import UIKit
import ObjectiveC

private var taskKey: UInt8 = 0

extension UIImageView {
    private var loadingTask: Task<Void, Never>? {
        get { objc_getAssociatedObject(self, &taskKey) as? Task<Void, Never> }
        set { objc_setAssociatedObject(self, &taskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func cancelImageLoad() {
        loadingTask?.cancel()
        loadingTask = nil
    }

    func setImage(from url: URL?,
                  targetSize: CGSize,
                  imageLoader: ImageLoaderProtocol,
                  placeholder: UIImage? = nil) {
        cancelImageLoad()
        image = placeholder
        guard let url else { return }

        let scale = UIScreen.main.scale
        loadingTask = Task { [weak self] in
            guard let self else { return }


            if let cached = await imageLoader.cachedImage(for: url,
                                                          targetSize: targetSize,
                                                          scale: scale) {
                if Task.isCancelled { return }
                await MainActor.run { self.image = cached }
                return
            }


            if let thumb = try? await imageLoader.thumbnail(for: url) {
                if Task.isCancelled { return }
                await MainActor.run { self.image = thumb }
            }


            do {
                let full = try await imageLoader.image(for: url,
                                                       targetSize: targetSize,
                                                       scale: scale)
                if Task.isCancelled { return }
                let prepared = await full.byPreparingForDisplay()
                if Task.isCancelled { return }

                await MainActor.run {
                    UIView.transition(
                        with: self,
                        duration: 0.2,
                        options: .transitionCrossDissolve
                    ) {
                        self.image = prepared
                    }
                }
            } catch {

            }
        }
    }
}
