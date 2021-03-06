//
//  CommentsViewController.swift
//  InstaClone
//
//  Created by ardMac on 18/04/2017.
//  Copyright © 2017 teamHearts. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseDatabase


class CommentsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var commentsTableView: UITableView! {
        didSet{
            commentsTableView.delegate = self
            commentsTableView.dataSource = self
            
            commentsTableView.register(CommentsTableViewCell.cellNib, forCellReuseIdentifier: CommentsTableViewCell.cellIdentifier)
        }
    }
    
    var selectedPost : Photo?
    var selectedPostID : String = ""
    
    
    var currentUser : FIRUser? = FIRAuth.auth()?.currentUser
    var currentUserName : String = ""
    var currentUserID : String = ""
    var profileImageUrl : String = ""
    
    
    var comments = [Comment]()
    
    var ref: FIRDatabaseReference!
    
    func clearTextFieldText(){
        commentTextField.text = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        ref = FIRDatabase.database().reference()
        setCurrentUserAndPostID()
        commentTextField.delegate = self
        observeComments()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height - 49
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height - 49
            }
        }
    }
    

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    @IBAction func postButtonTapped(_ sender: Any) {
        handleSend()
    }
    
    func setCurrentUserAndPostID() {
        if let id = currentUser?.uid {
            print(id)
            currentUserID = id
        }
        
        self.ref.child("users").child(currentUserID).observe(.value, with: { (userSS) in
            print("Value : " , userSS)
            
            let dictionary = userSS.value as? [String: Any]
            
            self.currentUserName = (dictionary?["userName"])! as! String
            self.profileImageUrl = (dictionary?["profileImageUrl"])! as! String
            
        })
        
        if let postID = selectedPost?.id {
            selectedPostID = postID
        }
        
    }
    

    
    func observeComments() {
        ref.child("posts").child("\(selectedPostID)").child("comments").observe(.childAdded, with: { (snapshot) in
            print(snapshot)
            
            guard let comments = snapshot.value as? NSDictionary else {return}
            
            self.addToComments(id: snapshot.key, commentInfo: comments)
           /* for (k, v) in comments {
                
                if let commentId = k as? String,
                   let dictionary = v as? [String: Any] {
                    self.addToComments(id: commentId, commentInfo: dictionary as NSDictionary)
                }
                
            }*/
            self.commentsTableView.reloadData()
        })
    }
    
    
    func handleSend() {
        let ref = FIRDatabase.database().reference().child("posts").child("\(selectedPostID)").child("comments")
        let childRef = ref.childByAutoId()
        let values: [String: Any] = ["text": commentTextField.text! as String, "userName": currentUserName as String, "userId": currentUser!.uid, "timestamp": "\(NSNumber(value: Int(Date().timeIntervalSince1970)))", "userProfileImageUrl": profileImageUrl as String]
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            //let recipientUserCommentsRef = FIRDatabase.database().reference().child("user-comments").child(toId)
            //recipientUserCommentsRef.updateChildValues([commentId: 1])
            self.clearTextFieldText()
        }
    }
    
    func addToComments(id : String, commentInfo: NSDictionary) {
        if let userName = commentInfo["userName"] as? String,
           let userId = commentInfo["userId"] as? String,
           let userProfileImageUrl = commentInfo["userProfileImageUrl"] as? String,
           let text = commentInfo["text"] as? String,
           let timestamp = commentInfo["timestamp"] as? String {
                let newComment = Comment(withAnId: id, aUserId: userId, aUserName: userName, aUserProfileImageUrl: userProfileImageUrl, aText: text, aTimestamp: timestamp)
                self.comments.append(newComment)
        }
    }

}

extension CommentsViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentsTableViewCell.cellIdentifier) as? CommentsTableViewCell
            else { return UITableViewCell()}
        let currentComment = comments[indexPath.row]
        let profilePicURL = currentComment.userProfileImageUrl
        cell.commentsTextView.text = currentComment.text
        cell.usernameLabel.text = currentComment.userName
        cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profilePicURL!)
        return cell
    }
}








