//
//  ProfileViewController.swift
//  ARKit Test
//
//  Created by Warren Hansen on 8/25/21.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var profileImage: UIImageView!
    
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profileImage.image = selectedImage
    }
    


}
