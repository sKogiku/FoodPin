//
//  RestaurantTableViewController.swift
//  FoodPin
//
//  Created by Simon Ng on 28/10/2019.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import UIKit
import CoreData

class RestaurantTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {

    @IBOutlet var emptyRestaurantView: UIView!
    
   var restaurants: [RestaurantMO] = []
   var fetchResultController: NSFetchedResultsController<RestaurantMO>!
   
   var searchController: UISearchController!
   var searchResults: [RestaurantMO] = []

   // MARK: - View controller life cycle
   
   override func viewDidLoad() {
       super.viewDidLoad()

       tableView.cellLayoutMarginsFollowReadableWidth = true
       
       // Set to use the large title of the navigation bar
       navigationController?.navigationBar.prefersLargeTitles = true
       
       // Configure the navigation bar
       navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
       navigationController?.navigationBar.shadowImage = UIImage()
       if let customFont = UIFont(name: "Rubik-Medium", size: 40.0) {
           navigationController?.navigationBar.largeTitleTextAttributes = [ NSAttributedString.Key.foregroundColor: UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0), NSAttributedString.Key.font: customFont ]
       }
       
       navigationController?.hidesBarsOnSwipe = true
       
       // Prepare the empty view
       tableView.backgroundView = emptyRestaurantView
       tableView.backgroundView?.isHidden = true
       
       // Fetch data from data store
       let fetchRequest: NSFetchRequest<RestaurantMO> = RestaurantMO.fetchRequest()
       let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
       fetchRequest.sortDescriptors = [sortDescriptor]
       
       if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
           let context = appDelegate.persistentContainer.viewContext
           fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
           
           fetchResultController.delegate = self
           
           do {
               try fetchResultController.performFetch()
               if let fetchedObjects = fetchResultController.fetchedObjects {
                   restaurants = fetchedObjects
               }
           } catch {
               print(error)
           }
       }
       
       // Search controller
       searchController = UISearchController(searchResultsController: nil)
       self.navigationItem.searchController = searchController
    // tableView.tableHeaderView = searchController.searchBar
       searchController.searchResultsUpdater = self
       searchController.obscuresBackgroundDuringPresentation = false
       searchController.searchBar.placeholder = "Search restaurants..."
       searchController.searchBar.barTintColor = .white
       searchController.searchBar.backgroundImage = UIImage()
       searchController.searchBar.tintColor = UIColor(red: 231, green: 76, blue: 60)
       searchController.automaticallyShowsCancelButton = true
      
   }

   override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       
       navigationController?.hidesBarsOnSwipe = true
   }
   
   override func viewDidAppear(_ animated: Bool) {
       if UserDefaults.standard.bool(forKey: "hasViewedWalkthrough") {
           return
       }
       
       let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
       if let walkthroughViewController = storyboard.instantiateViewController(withIdentifier: "WalkthroughViewController") as? WalkthroughViewController {
           
           present(walkthroughViewController, animated: true, completion: nil)
       }
   }
   
   // MARK: - NSFetchedResultsControllerDelegate methods
   
   func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
       tableView.beginUpdates()
   }
   
   func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
       
       switch type {
           
       case .insert:
           if let newIndexPath = newIndexPath {
               tableView.insertRows(at: [newIndexPath], with: .fade)
       }
           
       case .delete:
           if let indexPath = indexPath {
               tableView.deleteRows(at: [indexPath], with: .fade)
           }
           
       case .update:
           if let indexPath = indexPath {
               tableView.reloadRows(at: [indexPath], with: .fade)
           }
           
       default:
           tableView.reloadData()
   }
       
       if let fetchedObjects = controller.fetchedObjects {
           restaurants = fetchedObjects as! [RestaurantMO]
       }
   }
   
   func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
       tableView.endUpdates()
   }
   
   // MARK: - Method for content filtering / Search bar
   func filterContent(for searchText: String) {
       
       searchResults = restaurants.filter({ (restaurant) -> Bool in
           if let name = restaurant.name,
               let location = restaurant.location {
               
               let isMatch = name.localizedCaseInsensitiveContains(searchText) || location.localizedCaseInsensitiveContains(searchText)
               
               return isMatch
           }
           return false
       })
   }
   
   // Method for displaying the search result
   func updateSearchResults(for searchController: UISearchController) {
       if let searchText = searchController.searchBar.text {
           filterContent(for: searchText)
           tableView.reloadData()
       }
   }
   
   
   
   // MARK: - Table view data source
   override func numberOfSections(in tableView: UITableView) -> Int {
       if restaurants.count > 0 {
           tableView.backgroundView?.isHidden = true
           tableView.separatorStyle = .singleLine
       } else {
           tableView.backgroundView?.isHidden = false
           tableView.separatorStyle = .none
       }
       
       return 1
   }

   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
       if searchController.isActive {
           return searchResults.count
       } else {
           return restaurants.count
       }
   }

   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
       let cellIdentifier = "datacell"
       let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! RestaurantTableViewCell
       
       // Determine if we get the restaurant from search result or the original array
       let restaurant = (searchController.isActive) ? searchResults[indexPath.row] : restaurants[indexPath.row]
       
       // Configure the cell...
       cell.nameLabel.text = restaurants[indexPath.row].name
       if let restaurantImage = restaurant.image {
           cell.thumbnailImageView.image = UIImage(data: restaurantImage as Data)
       }

       cell.locationLabel.text = restaurant.location
       cell.typeLabel.text = restaurant.type
       cell.heartImageView.isHidden = restaurant.isVisited ? false : true
       
       return cell
   }
   
   // This code makes a cell non-editable when the search controller is active
   override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
       if searchController.isActive {
           return false
       } else {
           return true
       }
   }
   
   // MARK: - Table view delegate
   
   override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
       
       let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
           // Delete the row from the data store
           if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
               let context = appDelegate.persistentContainer.viewContext
               let restaurantToDelete = self.fetchResultController.object(at: indexPath)
               
               context.delete(restaurantToDelete)
               
               appDelegate.saveContext()
           }
           
           // Call completion handler with true to indicate
           completionHandler(true)
       }
       
       let shareAction = UIContextualAction(style: .normal, title: "Share") { (action, sourceView, completionHandler) in
           let defaultText = "Just checking in at " + self.restaurants[indexPath.row].name!
           
           let activityController: UIActivityViewController
           
           if let restaurantImage = self.restaurants[indexPath.row].image,
               let imageToShare = UIImage(data: restaurantImage as Data) {
               activityController = UIActivityViewController(activityItems: [defaultText, imageToShare], applicationActivities: nil)
           } else  {
               activityController = UIActivityViewController(activityItems: [defaultText], applicationActivities: nil)
           }
           
           // For iPad
           if let popoverController = activityController.popoverPresentationController {
               if let cell = tableView.cellForRow(at: indexPath) {
                   popoverController.sourceView = cell
                   popoverController.sourceRect = cell.bounds
               }
           }
           
           self.present(activityController, animated: true, completion: nil)
           completionHandler(true)
       }
       
       // Customize the color
       deleteAction.backgroundColor = UIColor(red: 231, green: 76, blue: 60)
       deleteAction.image = UIImage(systemName: "trash")

       shareAction.backgroundColor = UIColor(red: 254, green: 149, blue: 38)
       shareAction.image = UIImage(systemName: "square.and.arrow.up")
       
       let swipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
       
       return swipeConfiguration
   }
   
   override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
       
       let checkInAction = UIContextualAction(style: .normal, title: "Check-in") { (action, sourceView, completionHandler) in
           
           let cell = tableView.cellForRow(at: indexPath) as! RestaurantTableViewCell
           self.restaurants[indexPath.row].isVisited = self.restaurants[indexPath.row].isVisited ? false : true
           cell.heartImageView.isHidden = self.restaurants[indexPath.row].isVisited ? false : true
           
           if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
               appDelegate.saveContext()
           }
           
           completionHandler(true)
       }
       
       let checkInIcon = restaurants[indexPath.row].isVisited ? "arrow.uturn.left" : "checkmark"
       checkInAction.backgroundColor = UIColor(red: 38, green: 162, blue: 78)
       checkInAction.image = UIImage(systemName: checkInIcon)
       
       let swipeConfiguration = UISwipeActionsConfiguration(actions: [checkInAction])
       
       if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
           appDelegate.saveContext()
       }
       
       return swipeConfiguration
   }
   

   // MARK: - Navigation
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       if segue.identifier == "showRestaurantDetail" {
           if let indexPath = tableView.indexPathForSelectedRow {
               let destinationController = segue.destination as! RestaurantDetailViewController
               destinationController.restaurant = (searchController.isActive) ? searchResults[indexPath.row]: restaurants[indexPath.row]
               // destinationController.hidesBottomBarWhenPushed = true
           }
       }
   }
   
   @IBAction func unwindToHome(segue: UIStoryboardSegue) {
       dismiss(animated: true, completion: nil)
   }
}
