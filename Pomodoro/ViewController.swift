//
//  ViewController.swift
//  Pomodoro
//
//  Created by limyunhwi on 2022/03/07.
//

import UIKit

enum TimerStatus{
    case start
    case pause
    case end
}

class ViewController: UIViewController {
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var toggleButton: UIButton!
    
    var duration = 60 //타이머에 설정된 시간을 초로 계산한 프로퍼티
    var timerStatus: TimerStatus = .end //타이머의 상태를 가진 프로퍼티
    
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
    
    @IBAction func tapCancelButton(_ sender: UIButton) {
        switch self.timerStatus {
        case .start, .pause:
            self.timerStatus = .end
            self.cancelButton.isEnabled = false
            self.setTimerInfoViewVisible(isHidden: true) //timerLabel과 progress 숨기기
            self.datePicker.isHidden = false
            self.toggleButton.isSelected = false //configureTogglrButton메서드에 의해 title이 '시작'으로 변경
        default:
            break
        }
    }
    
    @IBAction func tapToggleButton(_ sender: UIButton) {
        self.duration = Int(self.datePicker.countDownDuration) //countDownDuration프로퍼티는 선택한 시간이 총 몇 초인지 알려준다.
        switch self.timerStatus {
        case .end:
            self.timerStatus = .start
            self.setTimerInfoViewVisible(isHidden: false) //timerLabel과 progress 보이게 하기
            self.datePicker.isHidden = true
            self.toggleButton.isSelected = true //configureToggleButton에 의해 title이 일시정지로 변경됨
            self.cancelButton.isEnabled = true
        case .start:
            self.timerStatus = .pause
            self.toggleButton.isSelected = false
        case .pause:
            self.timerStatus = .start
            self.toggleButton.isSelected = true
        }
    }
}

