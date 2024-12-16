import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput // Input da Apple Pencil e touch
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Aggiornamenti alla vista se necessario
    }
}

struct CanvasView: View {
    @State private var canvasView = PKCanvasView()
    @State private var toolPickerVisible = true
    private let toolPicker = PKToolPicker()
    @State private var savedDrawings: [UIImage] = []
    @State private var showingGallery = false

    @Environment(\.colorScheme) var colorScheme // Rileva la modalità chiara/scura

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Button(action: clearCanvas) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                }
                .padding()
                .accessibilityLabel("Clear Canvas")
                Spacer()
                Button(action: saveDrawing) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                }
                .padding()
                .accessibilityLabel("Save Canvas")
                Spacer()
                Button(action: toggleToolPicker) {
                    Image(systemName: toolPickerVisible ? "pencil.slash" : "pencil")
                        .foregroundColor(.teal)
                        .font(.system(size: 20))
                }
                .padding()
                .accessibilityLabel("Toggle Tool Picker")
                Spacer()
                Button(action: { showingGallery = true }) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundColor(.purple)
                        .font(.system(size: 20))
                }
                .padding()
                .accessibilityLabel("Show Gallery")
            }
            .padding(.horizontal)
            .background(Color(UIColor.systemGray6))

            // Canvas
            DrawingCanvasView(canvasView: $canvasView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(colorScheme == .dark ? UIColor.systemGray5 : UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.1), radius: 4, x: 0, y: 2)
                .padding()
                .onAppear {
                    showToolPicker()
                }
        }
        .background(Color(UIColor.systemGray5).edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showingGallery) {
            GalleryView(savedDrawings: $savedDrawings)
        }
    }

    private func clearCanvas() {
        withAnimation {
            canvasView.drawing = PKDrawing()
        }
    }

    private func saveDrawing() {
        let image = canvasView.drawing.image(from: canvasView.bounds, scale: 1.0)
        savedDrawings.append(image)
        print("Drawing saved to in-app gallery.")
    }

    private func toggleToolPicker() {
        withAnimation {
            if toolPickerVisible {
                hideToolPicker()
            } else {
                showToolPicker()
            }
        }
    }

    private func showToolPicker() {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        toolPickerVisible = true
    }

    private func hideToolPicker() {
        toolPicker.setVisible(false, forFirstResponder: canvasView)
        toolPicker.removeObserver(canvasView)
        toolPickerVisible = false
    }
}

struct GalleryView: View {
    @Binding var savedDrawings: [UIImage]
    @State private var selectedImage: IdentifiableImage? = nil
    @State private var showDeleteAlert = false
    @State private var indexToDelete: Int? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(savedDrawings.indices, id: \.self) { index in
                        ZStack {
                            Color(UIColor.systemGray5)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Image(uiImage: savedDrawings[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width / 3 - 16, height: UIScreen.main.bounds.width / 3 - 16)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    selectedImage = IdentifiableImage(image: savedDrawings[index])
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        indexToDelete = index
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Gallery")
            .sheet(item: $selectedImage) { selected in
                ImageDetailView(image: selected.image, onDelete: {
                    if let index = savedDrawings.firstIndex(of: selected.image) {
                        savedDrawings.remove(at: index)
                    }
                })
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Drawing"),
                    message: Text("Are you sure you want to delete this drawing?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let index = indexToDelete {
                            savedDrawings.remove(at: index)
                        }
                        indexToDelete = nil
                    },
                    secondaryButton: .cancel {
                        indexToDelete = nil
                    }
                )
            }
        }
    }
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ImageDetailView: View {
    let image: UIImage
    var onDelete: () -> Void

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 4)
                .padding()

            Spacer()
        }
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    CanvasView()
}
