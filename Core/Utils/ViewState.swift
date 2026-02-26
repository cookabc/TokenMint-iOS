/// Generic view state for async data loading.
enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case error(AppError)
}
