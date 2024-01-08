//
//  ProfileImageViewController.swift
//  Selection
//
//  Created by 김정원 on 1/2/24.
//

import UIKit

// ProfileImageViewController.swift

class ProfileImageViewController: UIViewController,UIScrollViewDelegate {
    @IBOutlet weak var profileImageView: UIImageView!
    var imageUrl: String?
    
    @IBOutlet weak var scrollView: UIScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        scrollView.maximumZoomScale = 2
        // URL을 사용하여 이미지 로드
        if let urlString = imageUrl, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let data = data, let image = UIImage(data: data) else {
                    return
                }
                
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                }
            }.resume()
        }
        
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return profileImageView
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.zoomScale <= 1.0 {
            scrollView.zoomScale = 1.0
        }
        
        if scrollView.zoomScale >= 2.0 {
            scrollView.zoomScale = 2.0
        }
    }
}

