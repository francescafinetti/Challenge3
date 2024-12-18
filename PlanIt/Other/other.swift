//
//  Untitled.swift
//  PlanIt
//
//  Created by Francesca Finetti on 18/12/24.
//

import SwiftUI
import AVFoundation

struct OtherTasksView: View {
    @State private var selectedDate: Int = Calendar.current.component(.day, from: Date())
    @State private var tasksForOther: [Int: [OtherTask]] = [:]
    @State private var audioForOther: [Int: [OtherAudioFile]] = [:]
    @State private var isModalPresented: Bool = false
    @Binding var tasksByDay: [Int: [Task]]

    var body: some View {
        NavigationStack {
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
                                                    .fill(day == selectedDate ? Color.purple : Color.clear)
                                                    .frame(width: 36, height: 36)
                                                Text("\(day)")
                                                    .font(.body)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(day == selectedDate ? .white : .accent)
                                            }

                                            ZStack {
                                                if let taskCount = tasksForOther[day]?.count, taskCount > 0 {
                                                    Circle()
                                                        .fill(Color.purple)
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
                            .foregroundColor(.purple)
                            .offset(y: 10)
                    }
                }
                .padding(.bottom, 20)

                List {
                    if let tasks = tasksForOther[selectedDate], !tasks.isEmpty {
                        Section(header: Text("Other Tasks").font(.headline)) {
                            ForEach(tasks) { task in
                                HStack {
                                    Button(action: {
                                        if let index = tasksForOther[selectedDate]?.firstIndex(where: { $0.id == task.id }) {
                                            tasksForOther[selectedDate]?[index].isCompleted.toggle()
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
                                tasksForOther[selectedDate]?.remove(atOffsets: indexSet)
                            }
                        }
                    }

                    if let audioFiles = audioForOther[selectedDate], !audioFiles.isEmpty {
                        Section(header: Text("Other Audio Notes").font(.headline)) {
                            ForEach(audioFiles) { audioFile in
                                HStack {
                                    Button(action: {
                                        if let index = audioForOther[selectedDate]?.firstIndex(where: { $0.id == audioFile.id }) {
                                            audioForOther[selectedDate]?[index].isCompleted.toggle()
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
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { index in
                                    if let audioFile = audioForOther[selectedDate]?[index] {
                                        try? FileManager.default.removeItem(at: audioFile.url)
                                    }
                                }
                                audioForOther[selectedDate]?.remove(atOffsets: indexSet)
                            }
                        }
                    }

                    if (tasksForOther[selectedDate]?.isEmpty ?? true) && (audioForOther[selectedDate]?.isEmpty ?? true) {
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
                            Text("Add Other Task")
                                .font(.body)
                                .fontWeight(.semibold)
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 25))
                            
                        }
                        .foregroundColor(.purple)
                    }
                    .padding(.leading, 190)

                    Spacer()
                }
                .padding(.bottom, 10)

                Spacer()
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .navigationTitle("Other")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $isModalPresented) {
            AddOtherTaskView(selectedDate: $selectedDate, tasksByDay: $tasksByDay, addTask: { task, day, audioURL in
                if tasksForOther[day] == nil {
                    tasksForOther[day] = []
                }
                if !task.name.isEmpty {
                    tasksForOther[day]?.append(task)
                }

                // Sync with tasksByDay in ContentView
                if tasksByDay[day] == nil {
                    tasksByDay[day] = []
                }
                tasksByDay[day]?.append(Task(name: task.name, isCompleted: task.isCompleted, time: task.time, category: "Other"))

                if let audioURL = audioURL {
                    if audioForOther[day] == nil {
                        audioForOther[day] = []
                    }
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                    let dateString = formatter.string(from: Date())
                    let renamedURL = audioURL.deletingLastPathComponent().appendingPathComponent("\(dateString).m4a")
                    try? FileManager.default.moveItem(at: audioURL, to: renamedURL)
                    audioForOther[day]?.append(OtherAudioFile(url: renamedURL))
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

struct OtherTask: Identifiable {
    let id = UUID()
    var name: String
    var isCompleted: Bool = false
    var time: String? // Optional time
}

struct OtherAudioFile: Identifiable {
    let id = UUID()
    var url: URL
    var isCompleted: Bool = false
    var time: String? // Optional time
}

struct OtherTasksView_Previews: PreviewProvider {
    static var previews: some View {
        OtherTasksView(tasksByDay: .constant([:]))
    }
}
