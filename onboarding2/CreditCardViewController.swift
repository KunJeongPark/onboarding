//
//  ViewController.swift
//  onboarding2
//
//  Created by Victoria Park on 1/11/23.
//

import UIKit

 import BraintreeCore
 import BraintreeCard
 import BraintreeApplePay
 import BraintreePayPal
 import PayPalDataCollector
 

class CreditCardViewController: UIViewController {
    
    @IBOutlet weak var cardNumberTextField: UITextField!
    @IBOutlet weak var addCardButton: UIButton! {
        didSet {
            addCardButton.layer.cornerRadius = 7
        }
    }
    var fetchedClientToken: String = ""
    var braintreeClient: BTAPIClient?
    
    @IBAction func addCardNumber(_ sender: Any) {
       submitTransaction()
    }
    
    func show(message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
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
            print("⚱️⚱️⚱️ client token \(clientToken)")
            if let clientToken = clientToken {
                completion(clientToken)
            }
            }.resume()
    }
    
    func postNonceToServer(paymentMethodNonce: String) {
        //    let deviceData = PPDataCollector.collectPayPalDeviceData()
        let json: [String: Any] = ["payment_method_nonce": "\(paymentMethodNonce)"]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        // could enter payment data from textField here
        
        let paymentURL = URL(string: "http://localhost:3000/checkout")!
        
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
    
    func submitTransaction() {
        // #3 customer submits payment info,
        // client SDK communicates to Braintree and returns nonce
        
        guard let braintreeClient = braintreeClient
        else {
            return
        }
        
         let cardClient = BTCardClient(apiClient: braintreeClient)
         let card = BTCard()
         card.number = "4111111111111111"
         card.expirationMonth = "12"
         card.expirationYear = "2025"
        // #3 customer submits payment info
        // client SDK communicates info to Braintree
         cardClient.tokenizeCard(card) { (tokenizedCard, error) in
             // BT server returns a payment method nonce
             if let tokenizedCard = tokenizedCard {
                 // #4 front-end sends payment method nonce to local server
                 self.postNonceToServer(paymentMethodNonce: tokenizedCard.nonce)
                 // Is there a return message so I can post alerts?
             } else {
                 self.show(message: "Payment Error!")
             }
         }
    }
    
    override func viewDidLoad(){
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

