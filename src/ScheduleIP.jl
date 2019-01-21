module ScheduleIP

using JSON2
using JuMP
using CPLEX

include("Visualization/draw.jl")
using .Draw

export solveSchedule, tasksToLanes, drawSchedule

function getjobinfo(filepath::String)
    open(filepath) do f
        global job_info = JSON2.read(f)
    end

    a=zeros(Int, length(job_info))
    b=zeros(Int, length(job_info))
    p=zeros(Int, length(job_info))

    for i =1:length(job_info)
        a[i] = job_info[i].least_start
        b[i] = job_info[i].max_end
        p[i] = job_info[i].length
    end
    a,b,p
end

function getlanelength(b)
    lane_length = maximum(b)
end

function solveSchedule(filepath::String, num_mcs::Int; verbose = true)
    a,b,p = getjobinfo(filepath)
    lane_length = getlanelength(b)
    num_jobs = length(a)

    @info "Creating IP Model"
    model = Model(JuMP.with_optimizer(CPLEX.Optimizer))

    @info "Adding Variables to Model"
    # Job i on Machine k
    @variable(model, X[1:num_jobs, 1:num_mcs], Bin)

    # Job i and Job j on Machine k
    @variable(model, Z[1:num_jobs, 1:num_jobs, 1:num_mcs], Bin)

    # Start Time of Job i on Machine K if assigned
    @variable(model, S[1:num_jobs, 1:num_mcs] >= 0)

    # Objective: Minimize ∑∑ X[i,k]
    @info "Setting Model Objective"
    w = sum(X);
    @objective(model, Min, w);

    @info "Adding Constraints to Model"
    # Create Before/ After Constraint
    # Had to do it funny like this because there is no
    # ord(i) != ord(j) in JuMP
    before_lhs = [];
    before_rhs = [];
    after_lhs = [];
    after_rhs = [];

    for k in 1:num_mcs
        for i in 1:num_jobs
            for j in 1:num_jobs
                if i != j
                    push!(before_lhs, (S[i,k]+(p[i]*X[i,k])-S[j,k]))
                    push!(before_rhs, lane_length*Z[i,j,k])
                    push!(after_lhs, (S[j,k]+(p[j]*X[j,k])-S[i,k]))
                    push!(after_rhs, lane_length*(1-Z[i,j,k]))
                end
            end
        end
    end

    @constraint(model, before, before_lhs .<= before_rhs)
    @constraint(model, after, after_lhs .<= after_rhs)

    # Load Constraint:
    @constraint(model, load[k=1:num_mcs], [sum(X[i,k]*p[i] for i in 1:num_jobs)] .<= lane_length)

    # Start Constraint:
    @constraint(model, start, [S[i,k] for k in 1:num_mcs for i in 1:num_jobs] .>= [a[i]*X[i,k] for k in 1:num_mcs for i in 1:num_jobs])

    # End Constraint:
    @constraint(model, End, [S[i,k] for k in 1:num_mcs for i in 1:num_jobs] .<= [(b[i]-p[i])*X[i,k] for k in 1:num_mcs for i in 1:num_jobs])

    # Assign Constraint:
    @constraint(model, assign[i=1:num_jobs], [sum(X[i,k] for k in 1:num_mcs)] .== 1)

    @info "Attempting to Find a Solution"
    optimize!(model)

    if verbose
        if JuMP.has_values(model)
            @info "Solution Found"
            # println(model)
            @info "Saving Model to [model.lp]"
            open("model.lp", "w") do f
                print(f, model)
            end
            @info "Objective Value" JuMP.objective_value(model)

        else
            # print(model)
            @warn "Model Exited With Status: $(JuMP.termination_status(model))"
        end
    end

    schedule = []
    for machine in 1:num_mcs
        for job in 1:num_jobs
            if JuMP.value(X[job, machine]) >= 1.0
                temp_dict = Dict()
                temp_dict[:job] = job
                temp_dict[:lane_id] = machine
                temp_dict[:start] = Int(floor(JuMP.value(S[job, machine])))
                temp_dict[:fin] = Int(floor(JuMP.value(S[job, machine])))+Int(floor(p[job]))

                push!(schedule, temp_dict)
            end
        end
    end

    return schedule
end


end
