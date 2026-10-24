import UIKit

protocol PhotoCarouselViewDelegate: AnyObject {
    func photoCarouselView(_ carouselView: PhotoCarouselView, didSelect item: PhotoCarouselItem, at index: Int)
    func photoCarouselView(_ carouselView: PhotoCarouselView, didChangePageTo index: Int)
}

extension PhotoCarouselViewDelegate {
    func photoCarouselView(_ carouselView: PhotoCarouselView, didSelect item: PhotoCarouselItem, at index: Int) {}
    func photoCarouselView(_ carouselView: PhotoCarouselView, didChangePageTo index: Int) {}
}

final class PhotoCarouselView: UIView {
    weak var delegate: PhotoCarouselViewDelegate?
    var imageLoader: ImageLoading = DefaultImageLoader.shared

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var pageNumberLabel: UILabel!

    private let reuseIdentifier = "PhotoCarouselCell"
    private var items: [PhotoCarouselItem] = []
    private var currentPage = 0
    private var isApplyingContent = false
    private var lastCollectionViewSize = CGSize.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // The carousel can be configured while its owning view still has a zero frame.
        // Lay out the nib content first, then rebuild the flow layout once a real size exists.
        collectionView.superview?.layoutIfNeeded()
        let collectionViewSize = collectionView.bounds.size
        guard collectionViewSize != .zero,
              collectionViewSize != lastCollectionViewSize else {
            return
        }

        lastCollectionViewSize = collectionViewSize
        layoutCurrentPageIfPossible()
    }

    func setContent(_ content: PhotoCarouselContent, initialPage: Int = 0) {
        isApplyingContent = true
        defer { isApplyingContent = false }

        switch content {
        case .items(let items):
            self.items = items
        case .empty, .loading, .failure:
            items = []
        }

        let maximumPage = max(items.count - 1, 0)
        currentPage = min(max(initialPage, 0), maximumPage)

        collectionView.reloadData()
        updateStatePresentation()
        layoutCurrentPageIfPossible()
    }

    private func commonInit() {
        let nib = UINib(nibName: "PhotoCarouselView", bundle: Bundle(for: PhotoCarouselView.self))
        guard let contentView = nib.instantiate(withOwner: self).first as? UIView else {
            assertionFailure("Unable to load PhotoCarouselView.xib")
            return
        }

        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.register(PhotoCarouselCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        updateStatePresentation()
    }

    private func updateStatePresentation() {
        let hasItems = !items.isEmpty
        pageControl.isHidden = !hasItems
        pageNumberLabel.isHidden = !hasItems
        pageControl.numberOfPages = items.count
        pageControl.currentPage = currentPage
        pageNumberLabel.text = hasItems ? "\(currentPage + 1) of \(items.count)" : nil
    }

    private func layoutCurrentPageIfPossible() {
        guard !items.isEmpty,
              collectionView.bounds.width > 0,
              collectionView.bounds.height > 0 else {
            return
        }

        let pageToDisplay = currentPage
        let wasApplyingContent = isApplyingContent
        isApplyingContent = true
        defer { isApplyingContent = wasApplyingContent }

        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(
            at: IndexPath(item: pageToDisplay, section: 0),
            at: .centeredHorizontally,
            animated: false
        )
        updateCurrentPage(pageToDisplay, notifyDelegate: false)
    }

    private func updateCurrentPage(_ page: Int, notifyDelegate: Bool) {
        guard items.indices.contains(page) else { return }

        let didChangePage = currentPage != page
        currentPage = page
        pageControl.currentPage = page
        pageNumberLabel.text = "\(page + 1) of \(items.count)"

        if didChangePage && notifyDelegate {
            delegate?.photoCarouselView(self, didChangePageTo: page)
        }
    }
}

extension PhotoCarouselView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        ) as? PhotoCarouselCell else {
            assertionFailure("Unexpected photo carousel cell type")
            return UICollectionViewCell()
        }

        cell.configure(with: items[indexPath.item], imageLoader: imageLoader)
        return cell
    }
}

extension PhotoCarouselView: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        (cell as? PhotoCarouselCell)?.cancelImageLoad()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.photoCarouselView(self, didSelect: items[indexPath.item], at: indexPath.item)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === collectionView, collectionView.bounds.width > 0, !items.isEmpty else { return }

        let page = Int((collectionView.contentOffset.x / collectionView.bounds.width).rounded(.toNearestOrAwayFromZero))
        updateCurrentPage(min(max(page, 0), items.count - 1), notifyDelegate: !isApplyingContent)
    }
}

extension PhotoCarouselView: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }
}
