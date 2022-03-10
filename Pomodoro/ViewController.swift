//
//  ViewController.swift
//  Pomodoro
//
//  Created by limyunhwi on 2022/03/07.
//

import UIKit
import AudioToolbox

enum TimerStatus{
    case start
    case pause
    case end
}
/*
 Timer클래스 대신 GCD API에 있는 dispathSourceTimer를 사용해 타이머를 만들어 보자.
 GCD는 GrandCentralDispatch의 약자로, 작업을 병렬적으로 처리하기 위해 애플이 제공하는 API이다.
 간단하게 쓰레드를 만들거나 관리해야하는 어려운 작업들을 맡아서 해주는데, 한 마디로 GCD를 이용하면 개발자들은 Task들이 담긴 큐를 만들고 큐를 GCD에 던져버리면 GCD가 모든 큐를 관리해준다.
 */
class ViewController: UIViewController {
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    var duration = 60 //타이머에 설정된 시간을 초로 계산한 프로퍼티
    var timerStatus: TimerStatus = .end //타이머의 상태를 가진 프로퍼티
    var timer: DispatchSourceTimer?
    var currentSeconds = 0 //현재 카운트다운되고 있는 시간을 초로 저장하는 프로퍼티
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureToggleButton()
    }

    func setTimerInfoViewVisible(isHidden: Bool) {
        self.timerLabel.isHidden = isHidden
        self.progressView.isHidden = isHidden
    }
    
    //시작 버튼의 상태에 따른 title 변경
    func configureToggleButton(){
        self.toggleButton.setTitle("시작", for: .normal) //기본 상태
        self.toggleButton.setTitle("일시정지", for: .selected) //선택되었을 때 상태
    }
    
    func startTimer(){
        if self.timer == nil {
            self.timer = DispatchSource.makeTimerSource(flags: [], queue: .main)//타이머이벤트를 모니터링하기 위한 새 dispatch 객체를 생성한다.
            //quueue 파라미터에서는 어떤 쓰레드 queue에서 반복 동작할 건지 정할 수 있다.
            //우리는 타이머가 돌 때마다 UI 작업을 해야한다, 남은 시간 표시하기
            //따라서 main 쓰레드에서 작업을 수행한다.
            //대부분 우리가 작성한 코드는 단 하나뿐인 main 스레드에서 실행된다.
            //그 이유는 우리가 작성한 코드가 Cocoa에서 실행되는데, 이 Cocoa가 코드를 main 스레드에서 호출하기 때문이다.
            //main 쓰레드에서 중요한 점은, main 스레드가 인터페이스 스레드라고도 불리는 점이다.
            //유저가 인터페이스에 접근하면 이벤트는 main 스레드에 전달되고 우리가 작성한 코드 이에 반응한다
            //이 말은 곧 인터페이스와 관련된 코드는 반드시 main스레드에서 실행되어야 함을 의미한다.
            //즉 UI와 관련된 코드는 main 스레드에서 실행되어야 한다.
            self.timer?.schedule(deadline: .now(), repeating: 1) //타이머의 주기 설정
            //deadline 파라미터에 .now()를 할당해 타이머가 시작되면 즉시 실행되게 만들어 준다.
            //3초 뒤에 시작되게 만들고 싶다면 .now() +3
            //repeating을 1초로 설정해 1초마다 반복되게 한다.
            self.timer?.setEventHandler(handler: { [weak self] in //캡쳐목록..?을 선언(나:메모리 누수방지를 위함으로 알고 있다)
                //타이머가 동작할 때마다 이 클로저가 호출되게 된다.
                guard let self = self else {return}//일시적으로 self가 strong 레퍼런스가 되도록 만든다.
                self.currentSeconds -= 1
                let hour = self.currentSeconds / 3600
                let minutes = (self.currentSeconds % 3600) / 60
                let seconds = (self.currentSeconds % 3600) % 60
                self.timerLabel.text = String(format: "%02d:%02d:%02d", hour, minutes, seconds) //%02d : 정수 숫자 두 자리
                //progress를 시간에 따라 줄어들게 만들기
                self.progressView.progress =  Float(self.currentSeconds) / Float(self.duration) //progress는 0부터 1까지의 값을 가진다.
                UIView.animate(withDuration: 0.5,delay: 0, animations: {
                    self.imageView.transform = CGAffineTransform(rotationAngle: .pi) //뷰를 180도로 회전시킨다.
                    //transform 프로퍼티를 사용해 뷰의 외형을 변경시켜준다.
                    //CGAffineTransform은 구조체인데 가장 큰 특징은 뷰의 프레임을 계산하지 않고 CGAffineTransform을 사용해 2D 그래픽을 그릴 수 있다.
                    //예) 뷰를 이동시키거나 스케일을 조정하거나 회전시키는 효과를 줄 수 있다.
                })
                //delay 프로퍼티를 0으로 설정해 애니메이션이 종료되자마자 바로 재시작하도록 한다.(애니메이션 반복)
                UIView.animate(withDuration: 0.5,delay: 0.5, animations: {
                    self.imageView.transform = CGAffineTransform(rotationAngle: .pi*2)
                })//delay를 0.5로 설정해 180도 애니메이션이 끝난 후 해당 애니메이션이 동작하게 설정한다,
                
                if self.currentSeconds <= 0 {
                    //타이머 종료
                    self.stopTimer()
                    //아이폰 기본 사운드 사용하기
                    //https://iphonedev.wiki/index.php/AudioServices 에서 시스템 사운드 id를 알 수 있다.
                    AudioServicesPlaySystemSound(1005)
                }
            }) //타이머와 연동될 이벤트 핸들러를 만들어 준다.
            self.timer?.resume() //타이버 시작
        }
    }
    
    func stopTimer(){
        if self.timerStatus == .pause {
            //timer르 suspend메서드를 호출해서 일시정지하게 되면 아직 수행해야하는 작업이 있음을 의미하기 때문에 suspend 타입이된 timer에 nil를 대입하면 런타임에러가 발생한다. 따라서 resume 메서드를 호출해 타이머를 실행시킨 후 nil을 대입해야한다. 
            self.timer?.resume()
        }
        self.timerStatus = .end
        self.cancelButton.isEnabled = false
//        self.setTimerInfoViewVisible(isHidden: true) //timerLabel과 progress 숨기기
//        self.datePicker.isHidden = false
        //투명도를 조절하는 alpha 값과 애니메이션을 사용해 사라지고 나타나는 모습을 부드럽게 처리한다.
        UIView.animate(withDuration: 0.5, animations: {
            self.timerLabel.alpha = 0
            self.progressView.alpha = 0
            self.datePicker.alpha = 1
            self.imageView.transform = .identity //이미지가 원상태로 돌아오게 한다.
        })
        self.toggleButton.isSelected = false //configureTogglrButton메서드에 의해 title이 '시작'으로 변경
        self.timer?.cancel() //타이머 종료
        self.timer = nil//메모리 해제, 이 작업을 하지 않으면 화면을 벗어나더라도 타이머가 계속 동작한다.
    }
    
    @IBAction func tapCancelButton(_ sender: UIButton) {
        switch self.timerStatus {
        case .start, .pause:
            self.stopTimer()
        default:
            break
        }
    }
    
    @IBAction func tapToggleButton(_ sender: UIButton) {
        self.duration = Int(self.datePicker.countDownDuration) //countDownDuration프로퍼티는 선택한 시간이 총 몇 초인지 알려준다.
        switch self.timerStatus {
        case .end:
            self.currentSeconds = self.duration
            self.timerStatus = .start
//            self.setTimerInfoViewVisible(isHidden: false) //timerLabel과 progress 보이게 하기
//            self.datePicker.isHidden = true
            //투명도를 조절하는 alpha 값과 애니메이션을 사용해 사라지고 나타나는 모습을 부드럽게 처리한다.
            UIView.animate(withDuration: 0.5, animations: {
                self.timerLabel.alpha = 1
                self.progressView.alpha = 1
                self.datePicker.alpha = 0
            })
            self.toggleButton.isSelected = true //configureToggleButton에 의해 title이 일시정지로 변경됨
            self.cancelButton.isEnabled = true
            self.startTimer()
        case .start:
            self.timerStatus = .pause
            self.toggleButton.isSelected = false
            self.timer?.suspend()//타이머 일시정지
        case .pause:
            self.timerStatus = .start
            self.toggleButton.isSelected = true
            self.timer?.resume() //타이머 다시 시작 시키기
        }
    }
}

