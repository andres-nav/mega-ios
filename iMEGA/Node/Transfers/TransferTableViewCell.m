#import "TransferTableViewCell.h"

#import <Photos/Photos.h>

#import "Helper.h"
#import "MEGAPauseTransferRequestDelegate.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGA-Swift.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

@import MEGAL10nObjc;
@import MEGAUIKit;

@interface TransferTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (nonatomic, getter=isThumbnailSet) BOOL thumbnailSet;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *pauseButton;

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;

@property (strong, nonatomic) MEGATransfer *transfer;
@property (strong, nonatomic) NSString *uploadTransferLocalIdentifier;

@end

@implementation TransferTableViewCell

#pragma mark - Public

- (void)configureCellForTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate {
    [self configureCellForTransfer:transfer overquota:false delegate:delegate];
}

- (void)configureCellForTransfer:(MEGATransfer *)transfer overquota:(BOOL)overquota delegate:(id<TransferTableViewCellDelegate>)delegate {
    self.delegate = delegate;
    self.overquota = overquota;
    self.transfer = transfer;
    self.uploadTransferLocalIdentifier = nil;
    
    self.nameLabel.text = [MEGASdk.shared unescapeFsIncompatible:transfer.fileName destinationPath:[NSHomeDirectory() stringByAppendingString:@"/"]];
    self.pauseButton.hidden = self.cancelButton.hidden = NO;
    
    if (UIColor.isDesignTokenEnabled) {
        self.nameLabel.textColor = [UIColor cellTitleColorFor:self.traitCollection];
        self.pauseButton.tintColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
        self.progressView.progressTintColor = [UIColor mnz_green00A886];
        self.backgroundColor = [UIColor mnz_backgroundElevated:self.traitCollection];
    }
    
    float percentage = ((float)transfer.transferredBytes / (float)transfer.totalBytes);
    self.progressView.progress = percentage;
    switch (transfer.type) {
        case MEGATransferTypeDownload: {
            MEGANode *node = [MEGASdk.shared nodeForHandle:transfer.nodeHandle];
            if (node) {
                [self.iconImageView mnz_setThumbnailByNode:node];
            } else {
                [self.iconImageView setImage:[NodeAssetsManager.shared imageFor:transfer.fileName.pathExtension]];
            }
            self.thumbnailSet = YES;
            break;
        }
            
        case MEGATransferTypeUpload: {
            if ([FileExtensionGroupOCWrapper verifyIsVisualMedia:transfer.fileName]) {
                NSString *transferThumbnailAbsolutePath = [[[NSHomeDirectory() stringByAppendingPathComponent:transfer.path] stringByDeletingPathExtension] stringByAppendingString:@"_thumbnail"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:transferThumbnailAbsolutePath]) {
                    self.iconImageView.image = [UIImage imageWithContentsOfFile:transferThumbnailAbsolutePath];
                    self.thumbnailSet = YES;
                } else {
                    [self.iconImageView setImage:[NodeAssetsManager.shared imageFor:transfer.fileName.pathExtension]];
                    self.thumbnailSet = NO;
                }
            } else {
                [self.iconImageView setImage:[NodeAssetsManager.shared imageFor:transfer.fileName.pathExtension]];
                self.thumbnailSet = YES;
            }
            break;
        }
            
        default:
            break;
    }
    
    [self configureCellWithTransferState:transfer.state];
    
    self.separatorView.layer.borderColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection].CGColor;
    self.separatorView.layer.borderWidth = 0.5;
}

- (void)reconfigureCellWithTransfer:(MEGATransfer *)transfer {
    self.uploadTransferLocalIdentifier = nil;
    self.transfer = transfer;
    
    [self configureCellWithTransferState:MEGATransferStateActive];
}

- (void)configureCellForQueuedTransfer:(NSString *)uploadTransferLocalIdentifier delegate:(id<TransferTableViewCellDelegate>)delegate {
    self.delegate = delegate;
    self.transfer = nil;
    self.uploadTransferLocalIdentifier = uploadTransferLocalIdentifier;
    
    if (!uploadTransferLocalIdentifier) {
        return;
    }
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[uploadTransferLocalIdentifier] options:nil];
    if (fetchResult == nil) {
        return;
    }
    
    PHAsset *asset = fetchResult.firstObject;
    if (asset == nil) {
        return;
    }
    
    NSString *extension;
    
    if ([PHAssetResource assetResourcesForAsset:asset].count > 0) {
        PHAssetResource *assetResource = [PHAssetResource assetResourcesForAsset:asset].firstObject;
        if (assetResource.originalFilename) {
            extension = [FileExtensionOCWrapper lowercasedLastExtensionIn:assetResource.originalFilename];
        }
    }
    
    NSString *name = asset.creationDate.mnz_formattedDefaultNameForMedia;
    if (extension) {
        name = [name stringByAppendingPathExtension:extension];
    }
    
    self.nameLabel.text = name;

    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.networkAccessAllowed = YES;
    
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:self.iconImageView.frame.size contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            self.iconImageView.image = result;
        } else {
            [self.iconImageView setImage:[NodeAssetsManager.shared imageFor:extension]];
        }
    }];
    
    [self queuedStateLayout];
}

- (void)reloadThumbnailImage {
    if (!self.isThumbnailSet) {
        NSString *transferThumbnailAbsolutePath = [[[NSHomeDirectory() stringByAppendingPathComponent:self.transfer.path] stringByDeletingPathExtension] stringByAppendingString:@"_thumbnail"];
        self.iconImageView.image = [UIImage imageWithContentsOfFile:transferThumbnailAbsolutePath];
    }
}

- (void)updatePercentAndSpeedLabelsForTransfer:(MEGATransfer *)transfer {
    self.transfer = transfer;
    [self configureCellWithTransferState:self.transfer.state];
}

- (NSMutableAttributedString *)transferInfoAttributedString {
    MEGATransfer *transfer = self.transfer;
    if (transfer.state == MEGATransferStateCancelled || transfer.state == MEGATransferStateFailed) {
        return NSMutableAttributedString.new;
    }
    
    UIColor *percentageColor = [self transferInfoColorFor:transfer.type];
    float percentage = ((float)transfer.transferredBytes / (float)transfer.totalBytes);
    self.progressView.progress = percentage;
    NSString *fileSize = [NSString memoryStyleStringFromByteCount:transfer.totalBytes];
    NSString *percentageCompleted = [NSString stringWithFormat:@"%.f %% of %@ ", percentage  * 100, fileSize];
    NSMutableAttributedString *percentageAttributedString = [NSMutableAttributedString.alloc initWithString:percentageCompleted attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1], NSForegroundColorAttributeName:percentageColor}];
    
    if (transfer.state == MEGATransferStateActive && ![[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
        NSString *speed = [NSString stringWithFormat:@"%@/s ", [NSString memoryStyleStringFromByteCount:transfer.speed]];
        NSAttributedString *speedAttributedString = [NSAttributedString.alloc initWithString:speed attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
        [percentageAttributedString appendAttributedString:speedAttributedString];
    }
    return percentageAttributedString;
}

- (void)updateTransferIfNewState:(MEGATransfer *)transfer {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
        if (self.transfer.state != transfer.state) {
            self.transfer = transfer;
            float percentage = ((float)transfer.transferredBytes / (float)transfer.totalBytes);
            self.progressView.progress = percentage;
            [self configureCellWithTransferState:self.transfer.state];
        }
    }
}

#pragma mark - Private
- (void)configureCellWithTransferState:(MEGATransferState)transferState {
    if (self.overquota && self.transfer.type == MEGATransferTypeDownload) {
        UIImage *image = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadingOverquotaTransferImage : UIImage.mnz_uploadingOverquotaTransferImage;
        [self setTransferStateIcon:image color:[self transferStateOverQuotaIconColor]];
        
        self.infoLabel.text = LocalizedString(@"Transfer over quota", @"Label indicating transfer over quota");
        self.infoLabel.textColor = UIColor.isDesignTokenEnabled ? [self transferStateOverQuotaTextColor] : UIColor.mnz_yellowFFCC00;
        
        self.pauseButton.hidden = self.cancelButton.hidden = NO;
        return;
    }
    switch (transferState) {
        case MEGATransferStateQueued: {
            UIImage *image = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadQueuedTransferImage : UIImage.mnz_uploadQueuedTransferImage;
            [self setTransferStateIcon:image color:[self transferTypeColorFor:self.transfer.type]];
            
            self.infoLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
            self.infoLabel.text = LocalizedString(@"queued", @"Queued");
            [self.pauseButton setImage:[UIImage imageNamed:@"pauseTransfers"] forState:UIControlStateNormal];
            self.pauseButton.hidden = self.cancelButton.hidden = NO;
            break;
        }
            
        case MEGATransferStateActive: {
            UIImage *defaultImage = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadingTransferImage : UIImage.mnz_uploadingTransferImage;
            UIColor *typeColor = [self transferTypeColorFor:self.transfer.type];
            [self setTransferStateIcon:defaultImage color:typeColor];
            [self.arrowImageView setNeedsDisplay];
            
            [self.pauseButton setImage:[UIImage imageNamed:@"pauseTransfers"] forState:UIControlStateNormal];
            self.pauseButton.hidden = self.cancelButton.hidden = NO;
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
                UIImage *queuedImage = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadQueuedTransferImage : UIImage.mnz_uploadQueuedTransferImage;
                [self setTransferStateIcon:queuedImage color:typeColor];
                NSAttributedString *status = [NSAttributedString.alloc initWithString:LocalizedString(@"paused", @"Paused") attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
                NSMutableAttributedString *infoLabel = [self transferInfoAttributedString];
                [infoLabel appendAttributedString:status];
                self.infoLabel.attributedText = infoLabel;
            } else {
                self.infoLabel.attributedText = [self transferInfoAttributedString];
            }

            break;
        }
            
        case MEGATransferStatePaused: {
            UIImage *image = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadQueuedTransferImage : UIImage.mnz_uploadQueuedTransferImage;
            [self setTransferStateIcon:image color:[self transferTypeColorFor:self.transfer.type]];
            
            NSAttributedString *status = [NSAttributedString.alloc initWithString:LocalizedString(@"paused", @"Paused") attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
            NSMutableAttributedString *infoLabel = [self transferInfoAttributedString];
            [infoLabel appendAttributedString:status];
            self.infoLabel.attributedText = infoLabel;
            [self.pauseButton setImage:[UIImage imageNamed:@"resumeTransfers"] forState:UIControlStateNormal];
            self.pauseButton.hidden = self.cancelButton.hidden = NO;
            break;
        }
            
        case MEGATransferStateRetrying: {
            UIImage *image = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadingTransferImage : UIImage.mnz_uploadingTransferImage;
            [self setTransferStateIcon:image color:[self transferTypeColorFor:self.transfer.type]];
            
            NSAttributedString *status;
            if (self.transfer.type == MEGATransferTypeUpload &&
                MEGASdk.shared.isStorageOverquota) {
                status = [NSAttributedString.alloc initWithString:LocalizedString(@"transfer.storage.quotaExceeded", @"") attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
            } else {
                status = [NSAttributedString.alloc initWithString:LocalizedString(@"Retrying...", @"Label for the state of a transfer when is being retrying - (String as short as possible).") attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
            }
            NSMutableAttributedString *infoLabel = [self transferInfoAttributedString];
            [infoLabel appendAttributedString:status];
            self.infoLabel.attributedText = infoLabel;
            self.pauseButton.hidden = self.cancelButton.hidden = NO;
            break;
        }
            
        case MEGATransferStateCompleting: {
            UIColor *statusColor = [self transferInfoColorFor:self.transfer.type == MEGATransferTypeDownload];
            NSAttributedString *status = [NSAttributedString.alloc initWithString:LocalizedString(@"Completing...", @"Label for the state of a transfer when is being completing - (String as short as possible).")
                                                                       attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1], NSForegroundColorAttributeName: statusColor}];
            NSMutableAttributedString *infoLabel = [self transferInfoAttributedString];
            [infoLabel appendAttributedString:status];
            self.infoLabel.attributedText = infoLabel;
            self.pauseButton.hidden = self.cancelButton.hidden = YES;
            }
            break;
            
        case MEGATransferStateCancelled: {
            UIImage *image = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadQueuedTransferImage : UIImage.mnz_uploadQueuedTransferImage;
            [self setTransferStateIcon:image color:[self transferTypeColorFor:self.transfer.type]];
            
            NSAttributedString *status = [NSAttributedString.alloc initWithString:LocalizedString(@"Cancelled", @"Possible state of a transfer. When the transfer was cancelled") attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
            NSMutableAttributedString *infoLabel = [self transferInfoAttributedString];
            [infoLabel appendAttributedString:status];
            self.infoLabel.attributedText = infoLabel;
            self.progressView.progress = 0;
            self.pauseButton.hidden = self.cancelButton.hidden = YES;
        }
            break;
            
        case MEGATransferStateFailed: {
            [self setTransferStateIcon:UIImage.mnz_errorTransferImage color:[self transferStateErrorIconColor]];
            
            UIColor *infoLabelTextColor = UIColor.isDesignTokenEnabled ? [self transferStateErrorTextColor] : [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
            self.infoLabel.textColor = infoLabelTextColor;
            
            NSString *transferFailed = LocalizedString(@"Transfer failed:", @"Notification message shown when a transfer failed. Keep colon.");
            NSString *errorString;
            if (self.transfer.isForeignOverquota) {
                errorString = LocalizedString(@"transfer.cell.shareOwnerStorageQuota.infoLabel", @"A message shown when uploading to an incoming share and the owner’s account is over its storage quota.");
            } else {
                MEGAError *error = self.transfer.lastErrorExtended;
                
                if (error.type == MEGAErrorTypeApiEBlocked && self.transfer.type != MEGATransferTypeUpload) {
                    errorString = LocalizedString(@"transfer.error.termsOfServiceViolation", @"Error shown when downloading a file that has violated Terms of Service.");
                } else {
                    errorString = [MEGAError errorStringWithErrorCode:error.type context:(self.transfer.type == MEGATransferTypeUpload) ? MEGAErrorContextUpload : MEGAErrorContextDownload];
                }
            }
            
            NSAttributedString *status = [NSAttributedString.alloc initWithString:[NSString stringWithFormat:@"%@ %@", transferFailed, LocalizedString(errorString, @"")] attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1], NSForegroundColorAttributeName:infoLabelTextColor}];
            NSMutableAttributedString *infoLabel = [self transferInfoAttributedString];
            [infoLabel appendAttributedString:status];
            self.infoLabel.attributedText = infoLabel;
            self.progressView.progress = 0;
            self.pauseButton.hidden = self.cancelButton.hidden = YES;
        }
            
            break;
        default: {
            UIImage *image = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadQueuedTransferImage : UIImage.mnz_uploadQueuedTransferImage;
            [self setTransferStateIcon:image color:[self transferTypeColorFor:self.transfer.type]];
            
            NSAttributedString *status = [NSAttributedString.alloc initWithString:LocalizedString(@"queued", @"Queued") attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
            NSMutableAttributedString *infoLabel = [self transferInfoAttributedString];
            [infoLabel appendAttributedString:status];
            self.infoLabel.attributedText = infoLabel;
            [self.pauseButton setImage:[UIImage imageNamed:@"pauseTransfers"] forState:UIControlStateNormal];
            self.pauseButton.hidden = self.cancelButton.hidden = NO;
            break;
        }
    }
}

- (void)queuedStateLayout {
    [self setTransferStateIcon:UIImage.mnz_uploadQueuedTransferImage color:[self transferTypeColorFor:MEGATransferTypeUpload]];
    
    self.infoLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    self.infoLabel.text = LocalizedString(@"pending", @"Label shown when a contact request is pending");
    self.pauseButton.hidden = YES;
    self.cancelButton.hidden = NO;
    self.progressView.progress = 0;
}

#pragma mark - IBActions

- (IBAction)cancelTransfer:(id)sender {
    if (self.transfer) {
        if ([MEGASdk.shared transferByTag:self.transfer.tag] != nil) {
            [MEGASdk.shared cancelTransferByTag:self.transfer.tag];
        } else {
            if ([MEGASdk.sharedFolderLink transferByTag:self.transfer.tag] != nil) {
                [MEGASdk.sharedFolderLink cancelTransferByTag:self.transfer.tag];
            }
        }
    } else if (self.uploadTransferLocalIdentifier) {
        [self.delegate cancelQueuedUploadTransfer:self.uploadTransferLocalIdentifier];
    }
}

- (IBAction)pauseTransfer:(id)sender {
    if (self.transfer) {
        MEGAPauseTransferRequestDelegate *pauseTransferDelegate = [[MEGAPauseTransferRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            MEGATransfer *transfer = [MEGASdk.shared transferByTag:self.transfer.tag];
            if (transfer) {
                self.transfer = transfer;
            } else {
                transfer = [MEGASdk.sharedFolderLink transferByTag:self.transfer.tag];
                if (transfer) {
                    self.transfer = transfer;
                }
            }
            
            [self.delegate pauseTransfer:self.transfer];
            [self configureCellWithTransferState:(request.flag) ? MEGATransferStatePaused : MEGATransferStateActive];
        }];
        
        MEGATransfer *transfer = [MEGASdk.shared transferByTag:self.transfer.tag];
        if (transfer) {
            [MEGASdk.shared pauseTransferByTag:self.transfer.tag pause:!(transfer.state == MEGATransferStatePaused) delegate:pauseTransferDelegate];
        } else {
            transfer = [MEGASdk.sharedFolderLink transferByTag:self.transfer.tag];
            if (transfer) {
                [MEGASdk.sharedFolderLink pauseTransferByTag:self.transfer.tag pause:!(transfer.state == MEGATransferStatePaused) delegate:pauseTransferDelegate];
            }
        }
    }
}

@end
