//
//  ProfileViewController.swift
//  
//
//  Created by bitbender on 4/15/17.
//
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var wholeView: UIView!
    
    @IBOutlet weak var postsCountLabel: UILabel!
    
    @IBOutlet weak var followersCountLabel: UILabel!
  
    @IBOutlet weak var followingCountLabel: UILabel!
    
    @IBOutlet weak var userImageView: UIImageView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var userDescLabel: UILabel!
    
    @IBOutlet weak var button: UIButton!
    
    
    @IBOutlet weak var imageCollectionView: UICollectionView! {
        didSet {
            imageCollectionView.dataSource = self
            imageCollectionView.delegate = self
            
        }
    }
    
    var photoList : [Photo] = []
    
    var ref: FIRDatabaseReference!
    
    var currentUser = User.currentUser
    
    var profileUserID = ""
    
    var isFollowed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        wholeView.isHidden = true
        
        ref = FIRDatabase.database().reference()
        listenToFirebase()
        
        // make the profile picture have a round radius
        userImageView.layer.masksToBounds = false
        userImageView.layer.cornerRadius = userImageView.frame.height/2
        userImageView.clipsToBounds = true
        
        // change the border color of button
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.layer.borderColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0).cgColor
        
        // check if user profile is the same as current user
        // if same button text = "Edit Profile"
        // if not button text = "Follow"
        print("current user id: \(currentUser.id!)")
        print("profile user id: \(profileUserID)")
        if self.profileUserID != self.currentUser.id! {
            self.button.addTarget(self, action: #selector(self.followUser), for: .touchUpInside)
        } else {
            self.button.setTitle("Edit Profile", for: .normal)
            self.button.addTarget(self, action: #selector(self.editProfile), for: .touchUpInside)
        }

    }
    
    func handleLogout() {
        
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let currentStoryboard = UIStoryboard (name: "Auth", bundle: Bundle.main)
        let initController = currentStoryboard.instantiateViewController(withIdentifier: "LogInViewController")
        present(initController, animated: true, completion: nil)
    }
    
    func followUser() {
        // ADD CODE TO FOLLOW A USER
        if isFollowed {
            ref.child("users").child(profileUserID).child("followers").child((currentUser.id)!).removeValue()
            ref.child("users").child((currentUser.id)!).child("following").child(profileUserID).removeValue()
            
            self.button.setTitle("Follow", for: .normal)
        } else {
    
            let following : [String : String] = [profileUserID : "true"]
            
            let follower : [String : String] = [currentUser.id! : "true"]
            
            ref.child("users").child(profileUserID).child("followers").updateChildValues(follower)
            ref.child("users").child((currentUser.id)!).child("following").updateChildValues(following)
            
            self.button.setTitle("Following", for: .normal)
        }
        isFollowed = !isFollowed
    }
    
    func editProfile() {
        // ADD CODE TO GO TO EDIT PROFILE VIEW
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let controller = storyboard .instantiateViewController(withIdentifier: "EditProfileTableViewController") as?
            EditProfileTableViewController else { return }
        if let selectedImage = userImageView.image {
            controller.selectedImage = selectedImage
        }
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func listenToFirebase() {
        
        if profileUserID == "" {
            profileUserID = (currentUser.id)!
        }
        
        ref.child("users").child(profileUserID).observe(.value, with: { (snapshot) in
            print("Value : " , snapshot)
            
            let dictionary = snapshot.value as? [String: Any]
            
            let currentProfileUser = User(withAnId: (snapshot.key), anEmail: (dictionary?["email"])! as! String, aName: (dictionary?["name"])! as! String, aScreenName: (dictionary?["userName"])! as! String, aDesc: (dictionary?["desc"])! as! String, aProfileImageURL: (dictionary?["profileImageUrl"])! as! String)
            
            self.ref.child("users").child((self.currentUser.id)!).child("following").child(self.profileUserID).observe(.value, with: { (instance) in
                print(instance)
                
                if instance.exists() {
                    self.isFollowed = true
                    self.button.setTitle("Following", for: .normal)
                }
                
            })
            
            // load screen name in nav bar
            self.navigationItem.title = currentProfileUser.userName
            
            
            // load the profile image
            self.userImageView.loadImageUsingCacheWithUrlString(urlString: currentProfileUser.profileImageUrl!)
            
            
            // load the user name
            self.userNameLabel.text = currentProfileUser.name
            
            // load the user description
            self.userDescLabel.text = currentProfileUser.desc
            
            self.wholeView.isHidden = false

        })
        
        ref.child("users").child(profileUserID).child("photos").observe(.value, with: { (snapshot) in
            print("Value : " , snapshot)
            
            if let photos = snapshot.value as? [String: Any] {
                for (k, v) in photos {
                    
                    if let dictionary = v as? [String: String] {
    
                        // fix when uploading photos has been changed with actual data (not just imageURL)
                        let newPhoto = Photo(withAnId : k, aUserID : "", aUserName : "", aLocation : "", aPostImageURL : dictionary["imageURL"]!, aUserProfileImageURL : "", aTimeStamp : "")
                        self.photoList.append(newPhoto)
                    }
                    
                }
                
                self.imageCollectionView.reloadData()
            }
            
        })

        
    }

}

extension ProfileViewController : UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCollectionViewCell", for: indexPath) as? PhotoCollectionViewCell else {return UICollectionViewCell()}
        
        cell.imageView.loadImageUsingCacheWithUrlString(urlString: photoList[indexPath.row].postImageUrl!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(photoList[indexPath.row].postImageUrl)
        
//        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
//        guard let controller = storyboard .instantiateViewController(withIdentifier: "PhotoShowController") as?
//            PhotoShowController else { return }
//        
//        controller.currentPhoto = photoList[indexPath.row]
//        
//        navigationController?.pushViewController(controller, animated: true)
    }
}

extension ProfileViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cellsAcross: CGFloat = 3
        let dim = CGFloat(collectionView.bounds.width / cellsAcross)
        return CGSize(width: dim, height: dim)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
      func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
      {
        return 0
    }
}

