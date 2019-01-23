using ScheduleIP

num_mcs = 4
num_threads = 48
EPGAP = 0.2

a,b,p = getjobinfo("Input/86jobs.json")
a=a[1:30]
b=b[1:30]
p=p[1:30]

# Attempt to find Solution
schedule = solveSchedule(a,b,p, num_mcs, EPGAP, num_threads)

# Draw Solution
lanes, max_length = tasksToLanes(schedule)
drawSchedule("4l-30t-schedule.png", lanes, max_length)
