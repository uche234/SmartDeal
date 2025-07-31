import UIKit
import CoreImage.CIFilterBuiltins

extension String {
    func qrCodeImage(scale: CGFloat = 10) -> UIImage? {
        let data = Data(self.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        guard let output = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let img = UIImage(ciImage: output.transformed(by: transform))
        return img
    }
}
