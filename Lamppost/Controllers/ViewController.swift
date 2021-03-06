//
//  ViewController.swift
//  kiOSk
//
//  Created by Spencer Edgecombe on 2018-02-03.
//  Copyright © 2018 kiOSK. All rights reserved.
//

import UIKit
import ContactsUI

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CNContactPickerDelegate {
    

    @IBOutlet var blurrView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet var slider: UISlider!
    @IBOutlet var topButton: UIButton!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    
    private var selectedCollections : [FlyerCollection]!
    private var selectedFlyers : [String : [Flyer]]!
    private var selectedCollection : FlyerCollection!
    private var userData : UserData!
    private var flyerData : [FlyerCollection] = []
    private var contactHandler : ContactHandler!
    private var inEditMode = false
    var contactsEnabled : Bool!
    
    override func viewDidLoad() {
        //Set size of the post
        
        contactsEnabled = CNContactStore.authorizationStatus(for: .contacts) == .authorized
        setUpViews()
        renderContacts()
        deleteButton.title = ""
        deleteButton.isEnabled = false
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        contactsEnabled = CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }
    
    func setUpViews() {
        
        
        
        tableView.register(UINib(nibName: FlyerCollectionCellView.NIB_NAME, bundle: nil), forCellReuseIdentifier: FlyerCollectionCellView.IDENTIFIER)
        tableView.register(UINib(nibName: TopCellView.NIB_NAME, bundle: nil), forCellReuseIdentifier: TopCellView.IDENTIFIER)
        self.tableView.rowHeight = 200
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width:UIScreen.main.bounds.width/3,height: 30)
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10)
        flowLayout.scrollDirection = UICollectionViewScrollDirection.horizontal
        flowLayout.minimumInteritemSpacing = 0.0
        
        slider.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2.0))
        slider.layer.cornerRadius = 15
        slider.layer.masksToBounds = true
        slider.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        slider.layer.borderColor = UIColor.darkGray.cgColor
        slider.layer.borderWidth = 0.25
        
        topButton.layer.cornerRadius = topButton.frame.height / 2
        topButton.layer.masksToBounds = true
        
        slider.minimumValue = 0
        slider.maximumValue = Float(tableView.rowHeight * CGFloat(tableView.numberOfRows(inSection: 0)))
        
        loadingIndicator.layer.cornerRadius = 10
        loadingIndicator.layer.masksToBounds = true
        loadingIndicator.isHidden = true
    }
    
    // Loads user data from UserDefaults and populates flyerData with stored data
    func loadUserData() {
        userData = UserData()
        
        if userData.isEmpty() {
            //no saved data
        } else {
            flyerData = userData.getFlyerData()
            tableView.reloadData()
        }
        
    }
    
    // Loads saved data and fetches all contacts to populate flyerData
    func renderContacts() {
        flyerData = []
        contactHandler = ContactHandler()
        //loadingIndicator.isHidden = false
        //loadingIndicator.startAnimating()
        loadUserData()
        contactHandler.requestPermission(completion: { granted in
            if granted {
                //self.contactHandler.importContacts()
                //self.flyerData.append(contentsOf: self.contactHandler.generateFlyers())
                self.tableView.reloadData()
            }
            //self.loadingIndicator.stopAnimating()
            self.loadingIndicator.isHidden = true
        })
    }
    
    // Adds selected contacts to a new or existing collection
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        contacts.forEach { contact in
            
            selectedCollection.addFlyer(flyer: contactHandler.getFlyerFromContact(contact: contact))
            
        }
        selectedCollection.sort()
        selectedCollection.isGroup = true
        
        if !userData.collectionExists(collectionName: selectedCollection.name) {
            flyerData.insert(selectedCollection, at: selectedCollection.order-1)
        }
        
        userData.addCollection(collection: selectedCollection)
        
        tableView.reloadData()
        
    }
    
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        
    }
    
    // Creates a new collection or selects existing one with collectionName
    // then launches contact picker to add to that collection
    func addToCollection(named: String) {
        
        if userData.collectionExists(collectionName: named) {
            for coll in flyerData {
                if coll.name == named {
                    selectedCollection = coll
                    break
                }
            }
        } else {
            selectedCollection = FlyerCollection(withName: named, order: UserData.numGroups+1, andFlyers: [])
        }
        
        let cnPicker = CNContactPickerViewController()
        cnPicker.delegate = self
        self.present(cnPicker, animated: true, completion: nil)
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        slider.isHidden = true
        topButton.isHidden = true
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //slider.isHidden = false
        topButton.isHidden = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        slider.setValue(Float(tableView.contentOffset.y), animated: true)
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        
        tableView.contentOffset = CGPoint(x: 0, y: CGFloat(slider.value))
    
    }
    
    @IBAction func topButtonPressed(_ sender: Any) {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flyerData.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell : FlyerCollectionCellView = self.tableView.dequeueReusableCell(withIdentifier: FlyerCollectionCellView.IDENTIFIER, for: indexPath) as! FlyerCollectionCellView
        cell.viewController = self
        cell.render(withCollection: flyerData[indexPath.row])
        return cell
    }
    
    
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        let deleteAlert = UIAlertController(title: "Delete flyers", message: "Are you sure you want to delete these flyers?", preferredStyle: .alert)
        let action = UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            self.deleteSelected()
        })
        
        deleteAlert.addAction(action)
        present(deleteAlert, animated: true, completion: nil)
    }
    
    
    @IBAction func editButtonPressed(_ sender: Any) {
        if inEditMode {
            exitEditMode()
        } else {
            enterEditMode()
        }
        if editButton.title == "Edit" {
            editButton.title = "Done"
            deleteButton.title = "Delete"
            deleteButton.isEnabled = true
        } else {
            editButton.title = "Edit"
            deleteButton.title = ""
            deleteButton.isEnabled = false
        }
    }
    
    
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        let settingsViewController = SettingsViewController()
        settingsViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        blurrView.isHidden = false
        settingsViewController.viewController = self
        present(settingsViewController, animated: true, completion: nil)
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        let addCollectionViewController = AddCollectionViewController()
        addCollectionViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        blurrView.isHidden = false
        addCollectionViewController.viewController = self
        present(addCollectionViewController, animated: true, completion: nil)
    }
    
    // Renders edit buttons and clears selected flyers and collections
    func enterEditMode() {
        inEditMode = true
        selectedCollections = []
        selectedFlyers = [:]
        tableView.reloadData()
    }
    
    // Renders normal mode
    func exitEditMode() {
        inEditMode = false
        tableView.reloadData()
    }
    
    func selectCollection(collection: FlyerCollection) {
        selectedCollections.append(collection)
    }
    
    func unselectCollection(collection: FlyerCollection) {
        var i = 0
        
        for col in selectedCollections {
            if col.name == collection.name {
                selectedCollections.remove(at: i)
                break
            }
            i = i + 1
        }
    }
    
    func selectFlyer(flyer : Flyer, collection: FlyerCollection) {
        if selectedFlyers[collection.name] == nil{
            selectedFlyers[collection.name] = []
        }
        selectedFlyers[collection.name]?.append(flyer)
    }
    
    func unselectFlyer(flyer : Flyer, collection : FlyerCollection) {
        var i = 0
        if selectedFlyers[collection.name] != nil {
            for fly in selectedFlyers[collection.name]! {
                if fly.title == flyer.title {
                    selectedFlyers[collection.name]?.remove(at: i)
                    break
                }
                i = i + 1
            }
        }
    }
    
    // Removes all selected folders from UserData and flyerData
    func deleteSelected() {
        for collection in selectedCollections {
            userData.removeCollection(collection: collection)
        }
        for collection in selectedFlyers {
            for flyer in collection.value {
                userData.removeFlyer(flyer: flyer, fromCollection: FlyerCollection(withName: collection.key, order: 0, andFlyers: []))
            }
        }
        renderContacts()
        selectedFlyers = [:]
        selectedCollections = []
    }
    
    func isInEditMode() -> Bool{
        return inEditMode
    }
    
    func getFlyerCount() -> Int {
        return flyerData.count
    }
    
    func getCollection(at: Int) -> FlyerCollection {
        if at < flyerData.count {
            return flyerData[at]
        } else {
            return flyerData.last!
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    

}

