//
//  PostCollectionViewCell.swift
//  Secretly
//
//  Created by Luis Ezcurdia on 28/05/21.
//  Copyright © 2021 3zcurdia. All rights reserved.
//

import UIKit

class PostCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "feedPostCell"
//    New var from Like
    var likeService: LikeService?
    var post: Post? {
        didSet {
           updateView()
            likeService = LikeService(post: post)
        }
    }
//    New IBOutlet from like's
//
//
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var labelLikeButton: UILabel!
    
    @IBOutlet weak var authorView: AuthorView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var commentCounter: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction func likePress(_ sender: UIButton){
        var likeNumber = self.post?.likesCount ?? 0
        likeService?.action() { [unowned self] result in
            switch result {
            case .success(nil):
                likeNumber = likeNumber - 1
                self.labelLikeButton.text = "\(likeNumber) likes"
                self.likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
            case .success( _):
                likeNumber = likeNumber + 1
                self.labelLikeButton.text = "\(likeNumber) likes"
                self.likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            case .failure(_):
                print("Fail Operation")
            }
            print("Numero de likes: ", likeNumber)
        }
    }
    
    func updateView() {

        imageView.image = nil
        guard let post = post else { return }
        if let color = UIColor(hex: post.backgroundColor) {
            self.backgroundColor = color
        }
        self.contentLabel.text = post.content
        self.commentCounter.text = String(describing: post.commentsCount ?? 0)
        if let postImg = post.image {
            ImageLoader.load(postImg.mediumUrl) { img in self.imageView.image = img }
        }
        self.authorView.author = post.user
    }
}
