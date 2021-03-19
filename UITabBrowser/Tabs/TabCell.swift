//
//  TabCell.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/01/28.
//

import UIKit

class TabCell: UICollectionViewCell {
    static let reuseIdentifier = "tab-cell-reuse-identifier"

    enum IconType: String {
        case none = ""
        case privateMode = "shield.lefthalf.fill"
        case pinned = "pin.fill"

        var name: String {
            self.rawValue
        }
    }

    var imageView = UIImageView()
    var secondaryImageView = UIImageView()
    var titleLabel = UILabel()
    var activityView = UIActivityIndicatorView(style: .medium)

    var isActivityAnimating: Bool {
        get {
            return activityView.isAnimating
        }
        set {
            if newValue {
                activityView.startAnimating()
            } else {
                activityView.stopAnimating()
            }
        }
    }

    private var secondaryImageViewFullWidthConstraint: NSLayoutConstraint! = nil
    private var secondaryImageViewZeroWidthConstraint: NSLayoutConstraint! = nil

    private var _iconType: IconType = .none
    var iconType: IconType {
        get { _iconType }
        set {
            if newValue == .none {
                secondaryImageView.image = UIImage()
                NSLayoutConstraint.deactivate([secondaryImageViewFullWidthConstraint])
                NSLayoutConstraint.activate([secondaryImageViewZeroWidthConstraint])
            } else {
                secondaryImageView.image = UIImage(systemName: newValue.name)
                NSLayoutConstraint.deactivate([secondaryImageViewZeroWidthConstraint])
                NSLayoutConstraint.activate([secondaryImageViewFullWidthConstraint])
            }
            _iconType = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        contentView.subviews.forEach { $0.removeFromSuperview() }
    }
}

extension TabCell {
    func configureCell() {
        let imageSize: CGFloat = 20.0
        let secondaryImageSize: CGFloat = 20.0
        let imageLeadingMargin: CGFloat = 4.0
        let titleLeadingMargin: CGFloat = 4.0
        let titleTrailingMargin: CGFloat = -4.0
        let contentOffsetY: CGFloat = 2.0

        secondaryImageViewFullWidthConstraint = secondaryImageView.widthAnchor.constraint(
            equalToConstant: secondaryImageSize
        )
        secondaryImageViewZeroWidthConstraint = secondaryImageView.widthAnchor.constraint(
            equalToConstant: .zero
        )

        imageView.translatesAutoresizingMaskIntoConstraints = false
        secondaryImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        activityView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        contentView.addSubview(secondaryImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(activityView)

        contentView.directionalLayoutMargins = .zero

        titleLabel.font = .systemFont(ofSize: 12.0)
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .left

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .lightGray
        secondaryImageView.contentMode = .scaleAspectFit
        secondaryImageView.tintColor = .lightGray

        NSLayoutConstraint.activate([
            // Progress View
            activityView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            activityView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            activityView.widthAnchor.constraint(equalTo: imageView.widthAnchor),
            activityView.heightAnchor.constraint(equalTo: imageView.heightAnchor),
            // Image View
            imageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: imageLeadingMargin
            ),
            imageView.widthAnchor.constraint(equalToConstant: imageSize),
            imageView.heightAnchor.constraint(equalToConstant: imageSize),
            imageView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor,
                constant: contentOffsetY
            ),
            // Title Label
            titleLabel.leadingAnchor.constraint(
                equalTo: imageView.trailingAnchor,
                constant: titleLeadingMargin
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: secondaryImageView.leadingAnchor
            ),
            titleLabel.heightAnchor.constraint(equalToConstant: imageSize),
            titleLabel.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor,
                constant: contentOffsetY
            ),
            // Secondary Image View
            secondaryImageView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor,
                constant: contentOffsetY
            ),
            secondaryImageView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: titleTrailingMargin
            ),
            secondaryImageView.heightAnchor.constraint(equalToConstant: imageSize),
            iconType == .none
                ? secondaryImageViewZeroWidthConstraint : secondaryImageViewFullWidthConstraint,
        ])
    }
}
