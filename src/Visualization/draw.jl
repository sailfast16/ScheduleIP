module Draw
    include("drawFuncs.jl");

    export drawSchedule, tasksToLanes

    function drawSchedule(out_name, lanes, max_length)
        lane_space = 5
        lane_height = 25
        lane_width = 500
        task_scale = lane_width/max_length

        draw_width = lane_width
        draw_height = getDrawHeight(lane_height, lane_space, length(lanes))

        # Draw
        Drawing(draw_width, draw_height, out_name)
        background(RGB(123/255, 166/255, 237/255))
        drawLanes(lanes, lane_height, lane_width, lane_space)
        scale(task_scale, 1)
        drawTasks(lanes, lane_height, lane_space)
        finish()
    end
end
