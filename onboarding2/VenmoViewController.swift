//
//  VenmoViewController.swift
//  onboarding2
//
//  Created by Victoria Park on 1/20/23.
//

import UIKit
import BraintreeCore
import BraintreeCard
import PayPalDataCollector
import PayPalCheckout
import BraintreeVenmo

class VenmoViewController: UIViewController {
    @IBOutlet weak var venmoButton: UIButton!{
        didSet {
            venmoButton.layer.cornerRadius = 7
        }
    }
    
    @IBAction func venmoPayPressed(_ sender: Any) {
        let request = BTVenmoRequest()
        request.vault = false // Set this and use a client token with a customer ID to vault
        request.paymentMethodUsage = .singleUse // available in v5.4.0+
        request.profileID = "1953896702662410263"
       
        self.venmoDriver?.tokenizeVenmoAccount(with: request) {(venmoAccount, error) in
           
            guard let account = venmoAccount
            else {
                return
            }
            self.postNonceToServer(paymentMethodNonce: account)
            // You got a Venmo nonce!
         /*   DispatchQueue.main.async {
                self.show(message: venmoAccount.nonce)
            }*/
        }
    }
    
    var venmoDriver : BTVenmoDriver?
    var apiClient : BTAPIClient!
    var fetchedClientToken: String = ""
   
    
    func show(message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func postNonceToServer(paymentMethodNonce: BTVenmoAccountNonce) {
        let deviceData = PPDataCollector.collectPayPalDeviceData(isSandbox: true)
        var json: [String: Any] = ["payment_method_nonce": "\(paymentMethodNonce.nonce)", "device_data": "\(deviceData)"]
        print("🚨📱 device data from client from function \(deviceData)")
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        let paymentURL = URL(string: "http://192.168.86.35:3000/checkoutVenmo")!
        
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
            DispatchQueue.main.async {
                
                print("responseString = \(String(describing: responseString))")
                self.show(message: "Your payment was received!")
            }
        }.resume()
    }
    
    func fetchClientToken(completion: @escaping (String) -> Void) {
        let clientTokenURL = URL(string: "http://192.168.86.35:3000/client_token")
        var clientTokenRequest = URLRequest(url: clientTokenURL!)
        clientTokenRequest.setValue("text/plain", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: clientTokenRequest) { (data, response, error) -> Void in
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
        fetchClientToken() {token in
           
            // #2 server generates and sends client token back using
            // server SDK (in app.js using braintree.gateway)
            self.fetchedClientToken = token
            
            self.apiClient = BTAPIClient(authorization: self.fetchedClientToken)
            self.venmoDriver = BTVenmoDriver(apiClient: self.apiClient)
            let isAppSwitch = self.venmoDriver?.isiOSAppAvailableForAppSwitch()
            print("💡💡💡 isAppSwitch \(isAppSwitch)")
            DispatchQueue.main.async {
                if let isAppSwitch = isAppSwitch {
                    if isAppSwitch {
                        self.venmoButton.isHidden = false
                    }
                    else {
                        self.venmoButton.isHidden = true
                    }
                }
                else {
                    self.venmoButton.isHidden = false
                }
            }
            
            DispatchQueue.main.async {
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
            }
        }
    
    }
    
}
