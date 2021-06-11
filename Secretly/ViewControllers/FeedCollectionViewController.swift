//
//  FeedCollectionViewController.swift
//  Secretly
//
//  Created by Luis Ezcurdia on 28/05/21.
//  Copyright © 2021 3zcurdia. All rights reserved.
//

import UIKit

class FeedCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, UICollectionViewDelegateFlowLayout {
    var posts: [Post]? {
        didSet {
            self.collectionView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    let refreshControl = UIRefreshControl()
    
    private var colorPicker = UIColorPickerViewController()
    
    @IBOutlet weak var postInputView: PostInputView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPosts()
    }

    func setupUI() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        let nib = UINib(nibName: String(describing: PostCollectionViewCell.self), bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: PostCollectionViewCell.reuseIdentifier)
        collectionView.addSubview(refreshControl)

        refreshControl.addTarget(self, action: #selector(self.loadPosts), for: UIControl.Event.valueChanged)
        
        colorPicker.delegate = self
        postInputView.colorPickerButton.addTarget(self, action: #selector(colorPickerButtonTapped), for: .touchUpInside)
        postInputView.postButton.addTarget(self, action: #selector(postButtonTapped), for: .touchUpInside)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostCollectionViewCell.reuseIdentifier, for: indexPath) as! PostCollectionViewCell

        cell.post = self.posts?[indexPath.row]
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    // MARK: UICollectionViewDataSourcePrefetching
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let indexPath = indexPaths.last else { return }
        print("=================================")
        print("\(indexPath.row)")
        print("=================================")
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 300)
    }

    // MARK: Rest logic

    let client = HttpClient(session: URLSession.shared, baseUrl: "https://secretlyapi.herokuapp.com")
    lazy var postEndpoint: RestClient<Post> = {
        return RestClient<Post>(client: client, path: "/api/v1/posts")
    }()

    @objc
    func loadPosts() {
        postEndpoint.list { [unowned self] result in
            guard let posts = try? result.get() else { return }
            DispatchQueue.main.async { self.posts = posts }
        }
    }
}

extension FeedCollectionViewController: UIColorPickerViewControllerDelegate {
    @objc func colorPickerButtonTapped() {
        colorPicker.selectedColor = postInputView.postTextView.backgroundColor ?? .clear
        present(colorPicker, animated: true)
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        self.postInputView.postTextView.backgroundColor = viewController.selectedColor
    }
}

//MARK: - Create and send Post
extension FeedCollectionViewController {
    @objc func postButtonTapped() {
        createPost {
            DispatchQueue.main.async { [weak self] in
                self?.postInputView.clear()
            }
        }
    }
    
    func createPost(onSuccess: (() -> Void)? = nil) {
        guard
            let postText = postInputView.postTextView.text,
            let postColor = postInputView.postTextView.backgroundColor?.hexString
        else {
            debugPrint("invalid post detected")
            return
        }

        let post = Post(content: postText, backgroundColor: postColor)
        let client = HttpClient(session: URLSession.shared, baseUrl: ApiConfig.baseURL.get()!)
        let postsEndpoint = RestClient<Post>(client: client, path: "/api/v1/posts")

        do {
            try postsEndpoint.create(model: post) { [unowned self] result in
                switch result {
                case .success(let post):
                    print("there is a new post \(post?.id ?? 0)")
                    onSuccess?()
                case .failure(let err):
                    DispatchQueue.main.async {
                        self.errorAlert(err)
                    }
                }
            }
        } catch let err {
            self.errorAlert(err)
        }
    }

    func errorAlert(_ error: Error) {
        let err = error as? Titleable
        let alert = UIAlertController(title: (err?.title ?? "Server Error"), message: error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}
