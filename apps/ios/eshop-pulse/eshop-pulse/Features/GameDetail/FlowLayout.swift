import SwiftUI

struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? .infinity
        let contentSize = layoutSize(for: subviews, maxWidth: maxWidth).size
        return CGSize(width: proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? contentSize.width, height: contentSize.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layoutSize(for: subviews, maxWidth: bounds.width)

        for (subview, origin) in zip(subviews, result.origins) {
            subview.place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                proposal: .unspecified
            )
        }
    }

    private func layoutSize(for subviews: Subviews, maxWidth: CGFloat) -> (size: CGSize, origins: [CGPoint]) {
        guard !subviews.isEmpty else { return (.zero, []) }

        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var contentWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }

            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + horizontalSpacing
            contentWidth = max(contentWidth, x - horizontalSpacing)
        }

        return (CGSize(width: contentWidth, height: y + rowHeight), origins)
    }
}
