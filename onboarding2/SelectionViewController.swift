//
//  SelectionViewController.swift
//  onboarding2
//
//  Created by Victoria Park on 1/12/23.
//

import UIKit
import BraintreeCard

class SelectionViewController: UIViewController {
    
    enum PaymentOptions: String {
        case creditCard = "Credit Card"
        case paypal = "PayPal"
        case venmo = "Venmo"
        case applePay = "Apple Pay"
        case googlePay = "Google Pay"
    }
    
    let paymentMethodsArray: [PaymentOptions] = [.creditCard, .paypal, .venmo, .applePay, .googlePay]
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PaymentCell")
    }
}

extension SelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch paymentMethodsArray[indexPath.row] {
        case .creditCard:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let creditCardViewController = storyboard.instantiateViewController(withIdentifier: "CreditCardViewController") as! CreditCardViewController
           // creditCardViewController.clientToken = "hello"
            navigationController?.pushViewController(creditCardViewController, animated: true)
            print("I need to embed this in nav")
        case .paypal:
            print("⌚️ paypal")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let paypalViewController = storyboard.instantiateViewController(withIdentifier: "PaypalViewController") as! PaypalViewController
            navigationController?.pushViewController(paypalViewController, animated: true)
        case .venmo:
            print("🥨 Venmo Selected")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let venmoViewController = storyboard.instantiateViewController(withIdentifier: "VenmoViewController") as! VenmoViewController
            navigationController?.pushViewController(venmoViewController, animated: true)
        default:
            print("others")
        }
    }
}

extension SelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paymentMethodsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCell", for: indexPath)
        cell.textLabel?.text = paymentMethodsArray[indexPath.row].rawValue
        return cell
    }
    
    
}
