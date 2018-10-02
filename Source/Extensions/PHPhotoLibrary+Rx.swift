//
//  PHPhotoLibrary+Rx.swift
//  RxPhotos
//
//  Created by Anton Romanov on 01/04/2018.
//  Copyright © 2018 Istered. All rights reserved.
//

import Foundation
import Photos
import RxSwift

extension Reactive where Base: PHPhotoLibrary {
    public static func requestAuthorization() -> Single<PHAuthorizationStatus> {
        return Single.create { single in
            PHPhotoLibrary.requestAuthorization { status in
                single(.success(status))
            }

            return Disposables.create()
        }
    }

    public func performChanges(_ changeBlock: @escaping () -> Void) -> Single<Bool> {
        return Single.create { [weak base] single in
            base?.performChanges(changeBlock) { result, error in
                if let error = error {
                    single(.error(error))
                } else {
                    single(.success(result))
                }
            }

            return Disposables.create()
        }
    }

    public var photoLibraryChange: Observable<PHChange> {
        let changeObserver = RxPHPhotoLibraryObserver()
        base.register(changeObserver)

        return Observable.create { [weak base] observable in
            changeObserver.changeCallback = observable.onNext

            return Disposables.create {
                base?.unregisterChangeObserver(changeObserver)
            }
        }
    }

    // MARK: -

    /// Save image to Photos.
    ///
    ///     let disposeBag = DisposeBag()
    ///     PHPhotoLibrary.shared().rx.save(img)
    ///         .subscribe(onSuccess: { (success) in
    ///             print(success)
    ///         }) { (error) in
    ///             print(error)
    ///         }
    ///         .disposed(by: disposeBag)
    ///
    /// - Parameter image: The image to save
    ///
    /// - Returns: An observable whose Element contain the local identifier of
    ///            the image saved if successful
    public func save(_ image: UIImage) -> Single<String> {
        return Single.create { [weak base] single in

            var savedImageIdentifier: String?
            base?.performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                savedImageIdentifier = request.placeholderForCreatedAsset?.localIdentifier
            }, completionHandler: { (success, error) in
                if success, let id = savedImageIdentifier {
                    single(.success(id))
                } else if let error = error {
                    single(.error(error))
                }
            })

            return Disposables.create()
        }
    }

}
