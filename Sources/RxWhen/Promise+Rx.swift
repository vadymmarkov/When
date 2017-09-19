#if !COCOAPODS
import When
#endif
import RxSwift

// MARK: - Observable

extension Promise: ObservableConvertibleType {
  public func asObservable() -> Observable<T> {
    return Observable.create({ observer in
      self
        .done({ value in
          observer.onNext(value)
        })
        .fail({ error in
          observer.onError(error)
        })
        .always({ _ in
          observer.onCompleted()
        })

      return Disposables.create()
    })
  }
}
