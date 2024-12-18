import SwiftUI
import AVFoundation

struct Task: Identifiable {
    let id = UUID()
    var name: String
    var isCompleted: Bool = false
    var time: String? // Ora opzionale
    var category: String? // Per distinguere Hobby, Quick Add, ecc.
}

struct AudioFile: Identifiable {
    let id = UUID()
    var url: URL
    var isCompleted: Bool = false
    var time: String? // Ora opzionale
}


struct AddTaskView: View {
    @Binding var selectedDay: Int
    @State private var taskName: String = ""
    @State private var selectedDate: Date = Date()
    @State private var audioRecorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var recordedAudioURL: URL?
    var addTask: (Task, Int, URL?) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $taskName)
                    
                    Button(action: {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }) {
                        HStack {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .foregroundColor(isRecording ? .red : .blue)
                            Text(isRecording ? "Stop Recording" : "Record Audio")
                        }
                    }
                    
                    if let audioURL = recordedAudioURL {
                        Text("Recorded: \(audioURL.lastPathComponent)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Section(header: Text("Date & Time")) {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(GraphicalDatePickerStyle())
                    DatePicker("Select Time", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                }
            }
            .navigationBarTitle("Add Task", displayMode: .inline)
            .navigationBarItems(trailing: Button("Save") {
                let calendar = Calendar.current
                let day = calendar.component(.day, from: selectedDate)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let timeString = timeFormatter.string(from: selectedDate)
                
                // Se il nome è vuoto ma c'è una registrazione, assegniamo un nome di default
                let finalTaskName = taskName.isEmpty && recordedAudioURL != nil ? "Audio Task" : taskName
                
                // Rinominare l'audio con un timestamp
                var finalAudioURL: URL? = nil
                if let url = recordedAudioURL {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                    let dateString = formatter.string(from: Date())
                    let renamedURL = url.deletingLastPathComponent().appendingPathComponent("\(dateString).m4a")
                    try? FileManager.default.moveItem(at: url, to: renamedURL)
                    finalAudioURL = renamedURL
                }
                
                // Passiamo il task e il file audio correttamente
                addTask(Task(name: finalTaskName, time: timeString, category: "Quick"), day, finalAudioURL)
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
}

struct CategoryView: View {
    var title: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(title)
                .tint(.accent)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: 100)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct TaskRow: View {
    let task: Task
    @Binding var tasksByDay: [Int: [Task]]
    let selectedDay: Int

    var body: some View {
        HStack {
            Button(action: {
                if let index = tasksByDay[selectedDay]?.firstIndex(where: { $0.id == task.id }) {
                    tasksByDay[selectedDay]?[index].isCompleted.toggle()
                }
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            VStack(alignment: .leading) {
                Text(task.name.isEmpty ? "Untitled Task" : task.name) // Task Name
                    .foregroundColor(task.isCompleted ? .black : .primary)
                if let time = task.time {
                    Text(time) // Time (Optional)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

