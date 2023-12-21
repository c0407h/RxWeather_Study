//
//  Mastering RxSwift
//  Copyright (c) KxCoding <help@kxcoding.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import CoreLocation
import RxSwift
import RxCocoa

//delegate proxy구현
//extension 추가 CLLocation Manager에 hasDelegate 프로토콜 구현

extension CLLocationManager: HasDelegate {
    public typealias Delegate = CLLocationManagerDelegate
    
    
}

//DelegateProxy클래스 선언
public class RxCLLocationManagerDelegateProxy: DelegateProxy<CLLocationManager, CLLocationManagerDelegate>, DelegateProxyType, CLLocationManagerDelegate {
    public init(locationManager: CLLocationManager) {
        super.init(parentObject: locationManager, delegateProxy: RxCLLocationManagerDelegateProxy.self)
    }
    
    
    public static func registerKnownImplementations() {
        self.register { RxCLLocationManagerDelegateProxy(locationManager: $0) }
    }
}


//CLLocationManager에 Reactive Extention 추가

extension Reactive where Base: CLLocationManager {
    //델리게이트 속성 추가 앞에서 구현한 델리게이트 프록시
    var delegate: DelegateProxy<CLLocationManager, CLLocationManagerDelegate> {
        return RxCLLocationManagerDelegateProxy.proxy(for: base)
    }
    
    //didUpdateLocation 속성 추가
    public var didUpdateLocation: Observable<[CLLocation]> {
        
        let sel = #selector(CLLocationManagerDelegate.locationManager(_:didUpdateLocations:))
        
        return delegate.methodInvoked(sel)
            .map { parameters in
            //gps로부터 새로운 위치정보가 전달되면 Cllocation 배열 방출
            return parameters[1] as! [CLLocation]
            }
    }
    
    //속성 추가
    public var didChangeAuthorizationStatus: Observable<CLAuthorizationStatus> {
        //허가 상태가 변경되는 시점마다 현재 상태를 방출하도록 구현
        let sel: Selector
        if #available(iOS 14.0, *) {
            sel = #selector(CLLocationManagerDelegate.locationManagerDidChangeAuthorization(_:))
        } else {
            sel = #selector(CLLocationManagerDelegate.locationManager(_:didChangeAuthorization:))
        }
        
        return delegate.methodInvoked(sel)
            .map { parameters in
                return CLAuthorizationStatus(rawValue: parameters[1] as! Int32) ?? .notDetermined
            }
    }
    
}

