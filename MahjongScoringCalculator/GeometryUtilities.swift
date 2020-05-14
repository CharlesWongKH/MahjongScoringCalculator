import CoreGraphics

func intersectionOverUnion(_ firstRect: CGRect, _ secondRect: CGRect) -> CGFloat {
    guard !firstRect.isEmpty, !secondRect.isEmpty else {
        return 0
    }

    let intersection = firstRect.intersection(secondRect)
    return intersection.area / (firstRect.area + secondRect.area - intersection.area)
}

private extension CGRect {

    var area: CGFloat {
        return width * height
    }
}

