using ScheduleIP

num_mcs = 5
# Attempt to find Solution
schedule = solveSchedule("Input/MS-20-windowedJobs3.json", num_mcs)

# Draw Solution
lanes, max_length = tasksToLanes(schedule)
drawSchedule("schedule.png", lanes, max_length)
