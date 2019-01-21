using Luxor
using JSON2
using Colors

function getSchedule(filename)
    schedule_list = []
    open(filename, "r") do f
        global schedule
        dicttxt = String(read(f))
        schedule_list = JSON2.read(dicttxt)
    end
    schedule_list
end

function getNumLanes(schedule_list)
    num_lanes = 0
    for task in schedule_list
        if task[:lane_id] > num_lanes
            num_lanes = task[:lane_id]
        end
    end
    num_lanes
end

function sortTasks(lane)
    starts = [lane[i][:start] for i =1:length(lane)]
    indsort = sortperm(starts)

    lane = [lane[i] for i in indsort]
    return lane
end

function tasksToLanes(schedule_list)
    lanes = []
    max_length = 0

    for lane_num = 1:getNumLanes(schedule_list)
        push!(lanes, [])
    end

    for lane_num = 1:getNumLanes(schedule_list)
        for task in schedule_list
            if task[:lane_id] == lane_num
                temp_task = Dict()
                temp_task[:name] = task[:job]
                temp_task[:lane] = task[:lane_id]
                temp_task[:length] = task[:fin] - task[:start]
                temp_task[:start] = task[:start]
                temp_task[:fin] = task[:fin]

                push!(lanes[lane_num], temp_task)

                if temp_task[:fin] > max_length
                    max_length = temp_task[:fin]
                end
            end
        end
    end

    for i = 1:length(lanes)
        lanes[i] = sortTasks(lanes[i])
    end

    lanes, max_length
end


function getDrawHeight(lane_height, lane_space, num_lanes)
    draw_height = (lane_height*num_lanes) +  ((num_lanes-1) * lane_space)
end

function drawLanes(lanes, lane_height, lane_width, lane_space)
    num_lanes = length(lanes)
    lanes_drawn = 0
    while lanes_drawn < num_lanes
        lane_y = (lanes_drawn * lane_height) + (lanes_drawn * lane_space-1)
        sethue("black")
        setline(3)
        rect(0, lane_y, lane_width, lane_height, :stroke)
        sethue("white")
        rect(0, lane_y, lane_width, lane_height, :fill)
        lanes_drawn+=1
    end
end

function drawTask(task, lane_height, lane_space)
    lane_id = task[:lane]
    task_y = ((lane_id-1) * lane_height) + ((lane_id-1) * lane_space - 1)
    sethue("black")
    setline(3)
    rect(task[:start], task_y, task[:length], lane_height, :stroke)
    sethue(RGB(229/255, 119/255, 119/255))
    rect(task[:start], task_y, task[:length], lane_height, :fill)
end

function drawTasks(lanes, lane_height, lane_space)
    for lane in lanes
        cur_fin = 0
        for task in lane
            if task[:start] < cur_fin
                println("Task $(task[:name]) IS OVERLAPPED")
            end
            drawTask(task, lane_height, lane_space)
            cur_fin = task[:fin]
        end
    end
end
