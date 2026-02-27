/// Generic view state for async data loading.
enum ViewState<T> {
    case idle
    case loading
    case retrying
    case success(T)
    case error(AppError)

    /// Whether the view should show a loading indicator.
    var isLoading: Bool {
        switch self {
        case .loading, .retrying: true
        default: false
        }
    }
}
