import SwiftUI
import AVFoundation

struct WorkTasksView: View {
    @State private var selectedDate: Int = Calendar.current.component(.day, from: Date())
    @State private var tasksForWork: [Int: [WorkTask]] = [:]
    @State private var audioForWork: [Int: [WorkAudioFile]] = [:]
    @State private var isModalPresented: Bool = false
    @Binding var tasksByDay: [Int: [Task]]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Divider()
                }
                .padding()

                VStack(spacing: 10) {
                    ZStack(alignment: .bottom) {
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(getDaysInCurrentMonth(), id: \ .self) { day in
                                        VStack(spacing: 4) {
                                            Text(getDayOfWeek(for: day))
                                                .font(.subheadline)
                                                .foregroundColor(.gray)

                                            ZStack {
                                                Circle()
                                                    .fill(day == selectedDate ? Color.teal : Color.clear)
                                                    .frame(width: 36, height: 36)
                                                Text("\(day)")
                                                    .font(.body)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(day == selectedDate ? .white : .black)
                                            }

                                            ZStack {
                                                if let taskCount = tasksForWork[day]?.count, taskCount > 0 {
                                                    Circle()
                                                        .fill(Color.teal)
                                                        .frame(width: 20, height: 20)
                                                    Text("\(taskCount)")
                                                        .font(.caption)
                                                        .foregroundColor(.white)
                                                } else {
                                                    Circle()
                                                        .fill(Color.clear)
                                                        .frame(width: 20, height: 20)
                                                }
                                            }
                                        }
                                        .onTapGesture {
                                            withAnimation {
                                                selectedDate = day
                                                proxy.scrollTo(day, anchor: .center)
                                            }
                                        }
                                        .id(day)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        proxy.scrollTo(selectedDate, anchor: .center)
                                    }
                                }
                            }
                        }

                        Image(systemName: "triangle.fill")
                            .resizable()
                            .frame(width: 12, height: 6)
                            .foregroundColor(.teal)
                            .offset(y: 10)
                    }
                }
                .padding(.bottom, 20)

                List {
                    if let tasks = tasksForWork[selectedDate], !tasks.isEmpty {
                        Section(header: Text("Work Tasks").font(.headline)) {
                            ForEach(tasks) { task in
                                HStack {
                                    Button(action: {
                                        if let index = tasksForWork[selectedDate]?.firstIndex(where: { $0.id == task.id }) {
                                            tasksForWork[selectedDate]?[index].isCompleted.toggle()
                                        }
                                    }) {
                                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(task.isCompleted ? .green : .gray)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(task.name)
                                            .foregroundColor(task.isCompleted ? .black : .primary)
                                        if let time = task.time {
                                            Text(time)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                tasksForWork[selectedDate]?.remove(atOffsets: indexSet)
                            }
                        }
                    }

                    if let audioFiles = audioForWork[selectedDate], !audioFiles.isEmpty {
                        Section(header: Text("Work Audio Notes").font(.headline)) {
                            ForEach(audioFiles) { audioFile in
                                HStack {
                                    Button(action: {
                                        if let index = audioForWork[selectedDate]?.firstIndex(where: { $0.id == audioFile.id }) {
                                            audioForWork[selectedDate]?[index].isCompleted.toggle()
                                        }
                                    }) {
                                        Image(systemName: audioFile.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(audioFile.isCompleted ? .green : .gray)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(audioFile.url.deletingPathExtension().lastPathComponent)
                                            .lineLimit(1)
                                        if let time = audioFile.time {
                                            Text(time)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                    Button(action: {
                                        playAudio(url: audioFile.url)
                                    }) {
                                        Image(systemName: "play.circle")
                                            .foregroundColor(.teal)
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { index in
                                    if let audioFile = audioForWork[selectedDate]?[index] {
                                        try? FileManager.default.removeItem(at: audioFile.url)
                                    }
                                }
                                audioForWork[selectedDate]?.remove(atOffsets: indexSet)
                            }
                        }
                    }

                    if (tasksForWork[selectedDate]?.isEmpty ?? true) && (audioForWork[selectedDate]?.isEmpty ?? true) {
                        VStack(spacing: 10) {
                            Spacer()
                            VStack(spacing: 10) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                    .opacity(0.5)
                                Text("Nothing planned for today!")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .opacity(0.5)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .listRowBackground(Color.clear)
                    }
                }
                .padding(.top, 20)

                HStack {
                    Button(action: {
                        isModalPresented = true
                    }) {
                        HStack {
                            Text("Add Work Task")
                                .font(.body)
                                .fontWeight(.semibold)
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 25))

                        }
                        .foregroundColor(.teal)
                    }
                    .padding(.leading, 210)

                    Spacer()
                }
                .padding(.bottom, 10)

                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .navigationTitle("Work")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $isModalPresented) {
            AddWorkTaskView(selectedDate: $selectedDate, tasksByDay: $tasksByDay, addTask: { task, day, audioURL in
                if tasksForWork[day] == nil {
                    tasksForWork[day] = []
                }
                if !task.name.isEmpty {
                    tasksForWork[day]?.append(task)
                }

                // Sync with tasksByDay in ContentView
                if tasksByDay[day] == nil {
                    tasksByDay[day] = []
                }
                tasksByDay[day]?.append(Task(name: task.name, isCompleted: task.isCompleted, time: task.time, category: "Work"))

                if let audioURL = audioURL {
                    if audioForWork[day] == nil {
                        audioForWork[day] = []
                    }
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                    let dateString = formatter.string(from: Date())
                    let renamedURL = audioURL.deletingLastPathComponent().appendingPathComponent("\(dateString).m4a")
                    try? FileManager.default.moveItem(at: audioURL, to: renamedURL)
                    audioForWork[day]?.append(WorkAudioFile(url: renamedURL))
                }

                isModalPresented = false // Close the modal after saving
            })
        }
    }

    private func getDaysInCurrentMonth() -> [Int] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        return Array(range)
    }

    private func getDayOfWeek(for day: Int) -> String {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.day = day
        let date = calendar.date(from: components) ?? Date()

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func playAudio(url: URL) {
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}

struct WorkTask: Identifiable {
    let id = UUID()
    var name: String
    var isCompleted: Bool = false
    var time: String? // Optional time
}

struct WorkAudioFile: Identifiable {
    let id = UUID()
    var url: URL
    var isCompleted: Bool = false
    var time: String? // Optional time
}

struct WorkTasksView_Previews: PreviewProvider {
    static var previews: some View {
        WorkTasksView(tasksByDay: .constant([:]))
    }
}

