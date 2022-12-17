import SwiftUI
import TimeLine

public struct MainMenuListItem: View {
    var type: MainMenuListItemType
    public var body: some View {
        HStack {
            type.image
                .imageScale(.large)
                .foregroundColor(.accentColor)
                .padding(.trailing)
            Text(type.title)
        }
        .padding()
    }
}

public enum MainMenuListItemType {
    case settings
    case compose
    case timeline(TimeLine.State.TimeLineType)
    
    var image: Image {
        switch self {
        case .settings:
            return Image(systemName: "gear")
        case .compose:
            return Image(systemName: "square.and.pencil")
        case .timeline(let timeLineTyoe):
            switch timeLineTyoe {
            case .home:
                return Image(systemName: "house")
            case .local:
                return Image(systemName: "map")
            case .federated:
                return Image(systemName: "globe")
            }
        }
    }
    
    var title: String {
        switch self {
        case .settings:
            return "Settings"
        case .compose:
            return "Post"
        case .timeline(let timeLineTyoe):
            return timeLineTyoe.title
        }
    }
}
