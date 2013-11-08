describe 'report builder', ->

  it 'shall build report for one month', ->
    report = new Report()
    task1 = {title: "test", cost: 3, cProjectName: "a"}
    report.addTasks(1,1, [task1])
    r = report.build()
    expect(r.projects).toEqual([
      {name: "a", sums: [3]}
    ])
    expect(r.dates).toEqual([
      {month:1, year:1, projects:[{name: "a", sum: 3, tasks: [task1]}]}
    ])

  it 'shall build report for several months', ->
    report = new Report()
    task1 = {title: "task-in-project-a", cost: 3, cProjectName: "a"}
    task2 = {title: "task-in-project-a", cost: 5, cProjectName: "a"}
    task3 = {title: "task-in-project-b", cost: 6, cProjectName: "b"}
    report.addTasks(1,1, [task1, task3])
    report.addTasks(2,1, [task2])
    r = report.build()
    expect(r.projects).toEqual([
      {name: "a", sums: [3, 5]}
      {name: "b", sums: [6, undefined]}
    ])
    expect(r.dates).toEqual([
      {month:1, year:1, projects:[{name: "a", sum: 3, tasks: [task1]},{name: "b", sum: 6, tasks: [task3]}]}
      {month:2, year:1, projects:[{name: "a", sum: 5, tasks: [task2]}]}
    ])
