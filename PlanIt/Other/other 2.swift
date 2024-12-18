//
//  Untitled.swift
//  PlanIt
//
//  Created by Francesca Finetti on 18/12/24.
//

import SwiftUI
import AVFoundation

struct AddOtherTaskView: View {
    @Binding var selectedDate: Int
    @Binding var tasksByDay: [Int: [Task]]
    @State private var taskName: String = ""
    @State private var selectedTaskTime: Date = Date()
    @State private var isRecording: Bool = false
    @State private var recordedAudioURL: URL?
    @State private var audioRecorder: AVAudioRecorder?

    var addTask: (OtherTask, Int, URL?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $taskName)

                    Button(action: {
                        isRecording ? stopRecording() : startRecording()
                    }) {
                        HStack {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .foregroundColor(isRecording ? .red : .purple)
                            Text(isRecording ? "Stop Recording" : "Record Audio")
                        }
                    }

                    if let url = recordedAudioURL {
                        Text("Recorded: \(url.lastPathComponent)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                Section(header: Text("Task Date & Time")) {
                    DatePicker("Select Date", selection: Binding(
                        get: { getDateFromDay(selectedDate) },
                        set: { selectedDate = getDayFromDate($0) }
                    ), displayedComponents: .date)

                    DatePicker("Select Time", selection: $selectedTaskTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
            .navigationTitle("Add Other Task")
            .navigationBarItems(trailing: Button("Save") {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let timeString = timeFormatter.string(from: selectedTaskTime)

                let task = OtherTask(name: taskName, isCompleted: false, time: timeString)
                
                addTask(task, selectedDate, recordedAudioURL)
            })
        }
    }

    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(UUID().uuidString + ".m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.record()
            recordedAudioURL = fileURL
            isRecording = true
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }

    private func getDateFromDay(_ day: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.day = day
        return calendar.date(from: components) ?? Date()
    }

    private func getDayFromDate(_ date: Date) -> Int {
        return Calendar.current.component(.day, from: date)
    }
}

struct AddOtherTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddOtherTaskView(selectedDate: .constant(18), tasksByDay: .constant([:]), addTask: { _, _, _ in })
    }
}
