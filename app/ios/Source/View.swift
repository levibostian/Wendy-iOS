import Wendy
import SwiftUI
import Combine

struct ContentView: View {
    
    @ObservedObject var viewModel = ViewModel()
    
    init() {
        Wendy.setup(taskRunner: MyWendyTaskRunner())
    }
    
    var body: some View {
        VStack {
            Text(viewModel.taskText)
                .font(.title)
            Button(action: {
                viewModel.addTasksThenRunWendy()
            }) {
                Text("Add Tasks")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    class ViewModel: ObservableObject, TaskRunnerListener {
        @Published var taskText: String = "Hello, World"
        
        init() {
            WendyConfig.addTaskRunnerListener(self)
        }
        
        func addTasksThenRunWendy() {
            Wendy.shared.addTask(tag: WendyTasks.addGroceryListItem, data: GroceryStoreItem(price: 5, name: "White bread"))
            Wendy.shared.addTask(tag: WendyTasks.addGroceryListItem, data: GroceryStoreItem(price: 1, name: "Butter"))
            Wendy.shared.addTask(tag: WendyTasks.addGroceryListItem, data: GroceryStoreItem(price: 4, name: "Bologna"))
            Wendy.shared.addTask(tag: WendyTasks.addGroceryListItem, data: GroceryStoreItem(price: 3, name: "American cheese"))
            
            Wendy.shared.runTasks(onComplete: nil)
        }

        func newTaskAdded(_ task: PendingTask) {}
        func runningTask(_ task: PendingTask) {
            // https://github.com/levibostian/Wendy-iOS/issues/142
            Task { @MainActor in
                self.taskText = "Running task..."
            }
        }
        func taskComplete(_ task: PendingTask, successful: Bool, cancelled: Bool) {}
        func taskSkipped(_ task: PendingTask, reason: ReasonPendingTaskSkipped) {}
        func allTasksComplete() {
            // https://github.com/levibostian/Wendy-iOS/issues/142
            Task { @MainActor in 
                self.taskText = "All tasks complete!"
            }
        }
    }

}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
