//sviluppi futuri: siri shortcuts per aggiungere velocemente delle task, e reminder delle tasks con una notifica, con la richiesta di permesso di attivare un Focus come non disturbare - aggiungi che si possono poi categorizzare successivamente dalla lista che si ha: cose che si devono fare successivamente ad integrazione SwiftData per salvataggio




//TASKS: FUNZIONANO

//QUICK VOICE TASK: NON ESCE RIPRODUZIONE AUDIO
//PERSONAL VOICE TASK: SI SALVA CON LA DATA IN PERSONAL E NON ESCE RIPRODUZIONE AUDIO NELLA CONTENT
//OTHER VOICE TASK: SI SALVA CON LA DATA IN OTHER E NON ESCE RIPRODUZIONE AUDIO NELLA CONTENT
//WORK VOICE TASK: SI SALVA CON LA DATA IN WORK E NON ESCE RIPRODUZIONE AUDIO NELLA CONTENT
//HOBBY VOICE TASK: SI SALVA UNO BENE IN HOBBY MA SI DUPLICA IDK WHY E CREA UN FILE UNTITLED E NON ESCE RIPRODUZIONE AUDIO NELLA CONTENT (ESCE DUPLICATO UNTITILED)



import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var selectedDay: Int = Calendar.current.component(.day, from: Date())
    @State private var tasksByDay: [Int: [Task]] = [:]
    @State private var audioFilesByDay: [Int: [AudioFile]] = [:]
    @State private var showModal: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    
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
                
                List {
                    // Sezione: Quick Added Tasks
                    if let quickTasks = tasksByDay[selectedDay]?.filter({ $0.category == "Quick" || $0.category == nil }), !quickTasks.isEmpty {
                        Section(header: Text("Quick Added Tasks").font(.headline)) {
                            ForEach(quickTasks) { task in
                                HStack {
                                    TaskRow(task: task, tasksByDay: $tasksByDay, selectedDay: selectedDay)
                                    
                                    // Cerca l'audio associato
                                    if let audioFile = audioFilesByDay[selectedDay]?.first(where: { $0.url.lastPathComponent.contains(task.name) }) {
                                        Spacer()
                                        Button(action: {
                                            playAudio(url: audioFile.url)
                                        }) {
                                            Image(systemName: "play.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title2)
                                        }
                                    }
                                }
                            }
                            .onDelete { indexSet in
                                tasksByDay[selectedDay]?.remove(atOffsets: indexSet)
                            }
                        }
                    }



                    // Sezione: Hobby Tasks
                    if let hobbyTasks = tasksByDay[selectedDay]?.filter({ $0.category == "Hobby" }), !hobbyTasks.isEmpty {
                        Section(header: Text("Hobby Tasks").font(.headline)) {
                            ForEach(hobbyTasks) { task in
                                TaskRow(task: task, tasksByDay: $tasksByDay, selectedDay: selectedDay)
                            }
                            .onDelete { indexSet in
                                tasksByDay[selectedDay]?.remove(atOffsets: indexSet)
                            }
                        }
                    }

                    // Sezione: Personal Tasks
                    if let personalTasks = tasksByDay[selectedDay]?.filter({ $0.category == "Personal" }), !personalTasks.isEmpty {
                        Section(header: Text("Personal Tasks").font(.headline)) {
                            ForEach(personalTasks) { task in
                                TaskRow(task: task, tasksByDay: $tasksByDay, selectedDay: selectedDay)
                            }
                            .onDelete { indexSet in
                                tasksByDay[selectedDay]?.remove(atOffsets: indexSet)
                            }
                        }
                    }

                    // Sezione: Work Tasks
                    if let workTasks = tasksByDay[selectedDay]?.filter({ $0.category == "Work" }), !workTasks.isEmpty {
                        Section(header: Text("Work Tasks").font(.headline)) {
                            ForEach(workTasks) { task in
                                TaskRow(task: task, tasksByDay: $tasksByDay, selectedDay: selectedDay)
                            }
                            .onDelete { indexSet in
                                tasksByDay[selectedDay]?.remove(atOffsets: indexSet)
                            }
                        }
                    }

                    // Sezione: Other Tasks
                    if let otherTasks = tasksByDay[selectedDay]?.filter({ $0.category == "Other" }), !otherTasks.isEmpty {
                        Section(header: Text("Other Tasks").font(.headline)) {
                            ForEach(otherTasks) { task in
                                TaskRow(task: task, tasksByDay: $tasksByDay, selectedDay: selectedDay)
                            }
                            .onDelete { indexSet in
                                tasksByDay[selectedDay]?.remove(atOffsets: indexSet)
                            }
                        }
                    }

                    // Sezione: Empty State
                    if (tasksByDay[selectedDay]?.isEmpty ?? true) {
                        VStack(spacing: 10) {
                            Spacer()
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .opacity(0.5)
                            Text("Nothing planned for today!")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .opacity(0.5)
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
                tasksByDay[day]?.append(task)
                
                // Aggiungi il file audio associato
                if let audioURL = audioURL {
                    if audioFilesByDay[day] == nil {
                        audioFilesByDay[day] = []
                    }
                    audioFilesByDay[day]?.append(AudioFile(url: audioURL))
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
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Errore nella riproduzione dell'audio: \(error.localizedDescription)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
