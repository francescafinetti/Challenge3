// aggiusta registrazioni audio delle categorie nella content
//aggiungi che si possono poi categorizzare successivamente dalla lista che si ha
//siri shortcuts per aggiungere task
//reminder delle task con notifica? - attivare non disturbare 
//accessibilità


import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var selectedDay: Int = Calendar.current.component(.day, from: Date())
    @State private var tasksByDay: [Int: [Task]] = [:]
    @State private var audioFilesByDay: [Int: [AudioFile]] = [:]
    @State private var showModal: Bool = false
    
    var body: some View {
        
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Today, \(formattedDate())")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Divider()
                }
                .padding()
                
                VStack(spacing: 10) {
                    ZStack(alignment: .bottom) {
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(daysInMonth(), id: \.self) { day in
                                        VStack(spacing: 4) {
                                            Text(weekday(for: day))
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            
                                            ZStack {
                                                Circle()
                                                    .fill(day == selectedDay ? Color.blue : Color.clear)
                                                    .frame(width: 36, height: 36)
                                                Text("\(day)")
                                                    .font(.body)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(day == selectedDay ? .white : .accent)
                                            }
                                            
                                            ZStack {
                                                if let tasksCount = tasksByDay[day]?.count, tasksCount > 0 {
                                                    Circle()
                                                        .fill(Color.blue)
                                                        .frame(width: 20, height: 20)
                                                    Text("\(tasksCount)")
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
                                                selectedDay = day
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
                                        proxy.scrollTo(selectedDay, anchor: .center)
                                    }
                                }
                            }
                        }
                        
                        Image(systemName: "triangle.fill")
                            .resizable()
                            .frame(width: 12, height: 6)
                            .foregroundColor(.blue)
                            .offset(y: 10)
                    }
                }
                
                .padding(.bottom, 20)
                
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        NavigationLink(destination: PersonalTasksView(tasksByDay: $tasksByDay)) {
                            CategoryView(title: "Personal", icon: "person.fill", color: .red)
                        }
                        NavigationLink(destination: HobbyTasksView(tasksByDay: $tasksByDay)) {
                            CategoryView(title: "Hobby", icon: "paintbrush.fill", color: .orange)
                        }
                    }
                    HStack(spacing: 20) {
                        NavigationLink(destination: WorkTasksView(tasksByDay: $tasksByDay)) {
                            CategoryView(title: "Work", icon: "briefcase.fill", color: .teal)
                        }
                        NavigationLink(destination: OtherTasksView(tasksByDay: $tasksByDay)) {
                            CategoryView(title: "Other", icon: "ellipsis.circle.fill",color: .purple)
                        }
                    }
                }
                .padding(.horizontal)
                
                List {// Quick Added Tasks
                    if let quickTasks = tasksByDay[selectedDay]?.filter({ $0.category == nil || $0.category == "Quick" }), !quickTasks.isEmpty {
                        Section(header: Text("Quick Added Tasks").font(.headline)) {
                            ForEach(quickTasks) { task in
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
                                tasksByDay[selectedDay]?.remove(atOffsets: indexSet)
                            }
                        }
                    }
                    
                    // Quick Added Audio
                    if let audioFiles = audioFilesByDay[selectedDay], !audioFiles.isEmpty {
                        Section(header: Text("Quick Audio Notes").font(.headline)) {
                            ForEach(audioFiles) { audio in
                                HStack {
                                    Button(action: {
                                        if let index = audioFilesByDay[selectedDay]?.firstIndex(where: { $0.id == audio.id }) {
                                            audioFilesByDay[selectedDay]?[index].isCompleted.toggle()
                                        }
                                    }) {
                                        Image(systemName: audio.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(audio.isCompleted ? .green : .gray)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(audio.url.lastPathComponent)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        if let time = audio.time {
                                            Text(time)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    Spacer()
                                    Button(action: {
                                        playAudio(url: audio.url)
                                    }) {
                                        Image(systemName: "play.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { index in
                                    if let audioFile = audioFilesByDay[selectedDay]?[index] {
                                        try? FileManager.default.removeItem(at: audioFile.url)
                                    }
                                }
                                audioFilesByDay[selectedDay]?.remove(atOffsets: indexSet)
                            }
                        }
                    }
                    
                    
                    // Hobby Tasks
                    if let hobbyTasks = tasksByDay[selectedDay]?.filter({ $0.category == "Hobby" }), !hobbyTasks.isEmpty {
                        Section(header: Text("Hobby Tasks").font(.headline)) {
                            ForEach(hobbyTasks) { task in
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
                                tasksByDay[selectedDay]?.remove(atOffsets: indexSet)
                            }
                        }
                    }
                    
                    // Other Tasks
                    if let otherTasks = tasksByDay[selectedDay]?.filter({ $0.category == "Other" }), !otherTasks.isEmpty {
                        Section(header: Text("Other Tasks").font(.headline)) {
                            ForEach(otherTasks) { task in
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
                                tasksByDay[selectedDay]?.remove(atOffsets: indexSet)
                            }
                        }
                    }
                    
                    // Work Tasks
                    if let workTasks = tasksByDay[selectedDay]?.filter({ $0.category == "Work" }), !workTasks.isEmpty {
                        Section(header: Text("Work Tasks").font(.headline)) {
                            ForEach(workTasks) { task in
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
                                tasksByDay[selectedDay]?.remove(atOffsets: indexSet)
                            }
                        }
                    }
                    
                    // Personal Tasks
                    if let personalTasks = tasksByDay[selectedDay]?.filter({ $0.category == "Personal" }), !personalTasks.isEmpty {
                        Section(header: Text("Personal Tasks").font(.headline)) {
                            ForEach(personalTasks) { task in
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
                                        Text(task.name)
                                            .foregroundColor(task.isCompleted ? .black : .primary)
                                        if let time = task.time {
                                            Text(time)
                                                .font(.caption)
                                                .foregroundColor(.accent)
                                        }
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                tasksByDay[selectedDay]?.remove(atOffsets: indexSet)
                            }
                        }
                    }
                    
                    // Empty State
                    if (tasksByDay[selectedDay]?.isEmpty ?? true) && (audioFilesByDay[selectedDay]?.isEmpty ?? true) {
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
                
                
                
                HStack {
                    Button(action: {
                        showModal = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 25))
                            Text("Quick Add Task")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    NavigationLink(destination: CanvasView()) {
                        HStack {
                            Text("Canvas")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Image(systemName: "scribble.variable")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                           
                        }
                    }
                    .padding(.trailing)
                }
                .padding(.bottom, 10)

                
                Spacer()
            }.background(Color(UIColor.systemGroupedBackground))
        }
        .sheet(isPresented: $showModal) {
            AddTaskView(selectedDay: $selectedDay, addTask: { task, day, audioURL in
                if tasksByDay[day] == nil {
                    tasksByDay[day] = []
                }
                if !task.name.isEmpty {
                    tasksByDay[day]?.append(task)
                }
                
                if let audioURL = audioURL {
                    if audioFilesByDay[day] == nil {
                        audioFilesByDay[day] = []
                    }
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                    let dateString = formatter.string(from: Date())
                    let renamedURL = audioURL.deletingLastPathComponent().appendingPathComponent("\(dateString).m4a")
                    try? FileManager.default.moveItem(at: audioURL, to: renamedURL)
                    audioFilesByDay[day]?.append(AudioFile(url: renamedURL))
                }
                
                showModal = false // Chiudi la modale dopo il salvataggio
            })
        }
    }
    
    private func daysInMonth() -> [Int] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())!
        return Array(range)
    }
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    private func weekday(for day: Int) -> String {
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
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
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
            .navigationBarItems(trailing:Button("Save") {
                let calendar = Calendar.current
                let day = calendar.component(.day, from: selectedDate)
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let timeString = timeFormatter.string(from: selectedDate)
                
                if let audioURL = recordedAudioURL {
                    addTask(Task(name: "", time: timeString), day, audioURL)
                } else if !taskName.isEmpty {
                    addTask(Task(name: taskName, time: timeString), day, nil)
                }
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

