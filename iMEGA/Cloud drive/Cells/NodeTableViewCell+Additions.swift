import MEGADesignToken
import MEGAL10n

extension NodeTableViewCell {
    @objc func setTitleAndFolderName(for recentActionBucket: MEGARecentActionBucket,
                                     withNodes nodes: [MEGANode]) {
  
        guard let firstNode = nodes.first else {
            infoLabel.text = ""
            nameLabel.text = ""
            return
        }
        
        let isNodeUndecrypted = firstNode.isUndecrypted(ownerEmail: recentActionBucket.userEmail ?? "",
                                                        in: .shared)
        guard !isNodeUndecrypted else {
            infoLabel.text = Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName
            nameLabel.text = Strings.Localizable.SharedItems.Tab.Recents.undecryptedFileName(nodes.count)
            return
        }
        
        let firstNodeName = firstNode.name ?? ""
        let nodesCount = nodes.count
        nameLabel.text = nodesCount == 1 ? firstNodeName : Strings.Localizable.Recents.Section.MultipleFile.title(nodesCount - 1).replacingOccurrences(of: "[A]", with: firstNodeName)

        let parentNode = MEGASdk.shared.node(forHandle: recentActionBucket.parentHandle)
        let parentNodeName = parentNode?.name ?? ""
        infoLabel.text = "\(parentNodeName) ・"
    }
    
    @objc func configureMoreButtonUI() {
        moreButton.tintColor = UIColor.isDesignTokenEnabled() ? TokenColors.Icon.secondary : UIColor.grayBBBBBB
    }
    
    @objc func setAccessibilityLabelsForIcons(in node: MEGANode) {
        labelImageView?.accessibilityLabel = MEGANode.string(for: node.label)
        favouriteImageView?.accessibilityLabel = Strings.Localizable.favourite
        linkImageView?.accessibilityLabel = Strings.Localizable.shared
    }

    @objc func configureIconsImageColor() {
        guard UIColor.isDesignTokenEnabled() else { return }
        
        configureIconImageColor(for: favouriteImageView)
        configureIconImageColor(for: linkImageView)
        configureIconImageColor(for: versionedImageView)
        configureIconImageColor(for: downloadedImageView)
    }

    private func configureIconImageColor(for imageView: UIImageView?) {
        guard let imageView else { return }
        imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = TokenColors.Icon.secondary
    }

    @objc func setCellBackgroundColor(with traitCollection: UITraitCollection) {
        var bgColor: UIColor = .black
        
        if UIColor.isDesignTokenEnabled() {
            bgColor = TokenColors.Background.page
        } else {
            bgColor = traitCollection.userInterfaceStyle == .dark ? UIColor.black1C1C1E : UIColor.whiteFFFFFF
        }
        
        backgroundColor = bgColor
    }
}
