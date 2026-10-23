import UIKit

final class ApplicationApartmentPhotoCell: UICollectionViewCell {
    let apartmentPhoto = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureImageView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureImageView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        apartmentPhoto.image = nil
    }

    private func configureImageView() {
        apartmentPhoto.translatesAutoresizingMaskIntoConstraints = false
        apartmentPhoto.contentMode = .scaleAspectFill
        apartmentPhoto.clipsToBounds = true
        contentView.addSubview(apartmentPhoto)
        NSLayoutConstraint.activate([
            apartmentPhoto.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            apartmentPhoto.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            apartmentPhoto.topAnchor.constraint(equalTo: contentView.topAnchor),
            apartmentPhoto.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
