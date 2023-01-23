//
//  PayPalViewController.swift
//  onboarding2
//
//  Created by Victoria Park on 1/19/23.
//

import UIKit

import BraintreeCore
import BraintreeCard
import BraintreeApplePay
import BraintreePayPal
import PayPalDataCollector
import PayPalCheckout

class PaypalViewController: UIViewController {
    
    var fetchedClientToken: String = ""
    var braintreeClient: BTAPIClient?
    
    @IBOutlet weak var paypalButton: UIButton! {
        didSet {
            paypalButton.layer.cornerRadius = 7
        }
    }
    
    @IBAction func paypalButtonPressed(_ sender: Any) {
        startCheckout()
    }
    
    func show(message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
  //  func postNonceToServer(paymentMethodNonce: String) {
    func postNonceToServer(paymentMethodNonce: BTPayPalAccountNonce) {
        //    let deviceData = PPDataCollector.collectPayPalDeviceData()
      //  let json: [String: Any] = ["payment_method_nonce": "\(paymentMethodNonce)"]
        var json: [String: Any] = ["payment_method_nonce": "\(paymentMethodNonce.nonce)"]
        if let lastName = paymentMethodNonce.lastName {
            json = ["payment_method_nonce": "\(paymentMethodNonce.nonce)", "lastName": "\(lastName)"]
        }
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        let paymentURL = URL(string: "http://localhost:3000/checkoutPaypal")!
        
        var request = NSMutableURLRequest(url: paymentURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
        request.httpBody = jsonData
        
        guard let jsonData = jsonData
        else {
            print("encoding error")
            return
        }
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                print("server error \(response.statusCode)")
                return
            }
            
            guard let data = data
            else {
                print("error getting data")
                return
            }
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            self.show(message: "Your payment was received!")
        }.resume()
    }
    
    func startCheckout() {
        guard let braintreeClient = braintreeClient
        else {
            return
        }
        
        let payPalDriver = BTPayPalDriver(apiClient: braintreeClient)
        
        // Specify the transaction amount here. "2.32" is used in this example.
        let request = BTPayPalCheckoutRequest(amount: "2.32")
        request.currencyCode = "USD" // Optional; see BTPayPalCheckoutRequest.h for more options
        
        payPalDriver.tokenizePayPalAccount(with: request) { [weak self] (tokenizedPayPalAccount, error) in
            // SFSafariVC
            guard let self = self
            else {
                return
            }
            if let tokenizedPayPalAccount = tokenizedPayPalAccount {
                print("Got a nonce: \(tokenizedPayPalAccount.nonce)")
                
                // Access additional information
                let email = tokenizedPayPalAccount.email
                let firstName = tokenizedPayPalAccount.firstName
                let lastName = tokenizedPayPalAccount.lastName
                let phone = tokenizedPayPalAccount.phone
                
                // See BTPostalAddress.h for details
                let billingAddress = tokenizedPayPalAccount.billingAddress
                let shippingAddress = tokenizedPayPalAccount.shippingAddress
             //   self.postNonceToServer(paymentMethodNonce: tokenizedPayPalAccount.nonce)
                self.postNonceToServer(paymentMethodNonce: tokenizedPayPalAccount)
            } else if let error = error {
                self.show(message: "error getting tokenized PayPalAccount")
            } else {
                // Buyer canceled payment approval
            }
        }
    }
     
    func fetchClientToken(completion: @escaping (String) -> Void) {
        let clientTokenURL = URL(string: "http://localhost:3000/client_token")
        let clientTokenRequest = NSMutableURLRequest(url: clientTokenURL!)
        clientTokenRequest.setValue("text/plain", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: clientTokenRequest as URLRequest) { (data, response, error) -> Void in
            // TODO: Handle errors
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                print("server error \(response.statusCode)")
                      return
            }
            
            guard let data = data
            else {
                print("error getting data")
                return
            }
            
            let clientToken = String(data: data, encoding: String.Encoding.utf8)
            if let clientToken = clientToken {
                completion(clientToken)
            }
            }.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        // #1 front end requests client token from server
        fetchClientToken() {[weak self] token in
            guard let self = self
            else {
                return
            }
            // #2 server generates and sends client token back using
            // server SDK (in app.js using braintree.gatewau
            self.fetchedClientToken = token
            
            self.braintreeClient = BTAPIClient(authorization: self.fetchedClientToken)
            
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
            }
        }
    }
}
