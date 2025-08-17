# AI_AcceleratorDesign
Designed and implemented a hardware accelerator for Tiny Neural Networks using Verilog HDL


Tiny Neural Network 하드웨어 가속기 설계 (Verilog)
Tiny Neural Network(TNN)의 주요 연산을 Verilog HDL을 사용하여 하드웨어로 구현하고, 최종적으로 추론(Inference) 과정을 가속하는 시스템을 설계하는 것을 목표로 합니다.

설계는 기본적인 연산 유닛부터 시작하여 점차 복잡한 모듈을 통합하는 Bottom-up 방식으로 진행되었습니다.

## 🚀 프로젝트 개요
최종적으로 구현된 TNN 가속기는 아래와 같은 구조를 가집니다. 외부 메모리에 저장된 입력 데이터(X)와 가중치(W1, W2)를 읽어와 두 개의 완전 연결 계층(Fully Connected Layer), 정규화(Normalization), ReLU 활성화 함수 연산을 순차적으로 수행하고, 최종 결과를 다시 메모리에 저장합니다.

<img width="940" height="217" alt="image" src="https://github.com/user-attachments/assets/8d79ab03-8559-444b-9cda-7e41d1894508" />


## 특징

모듈화된 설계: Adder, Multiplier, MAC, Systolic Array 등 재사용 가능한 모듈 단위로 설계

타일링(Tiling): 4x4 연산 유닛을 활용하여 8x8 행렬 곱셈을 효율적으로 처리

파이프라이닝: 각 계층이 순차적으로 동작하며 데이터 처리량(Throughput) 향상

유연한 배치 처리: 8-batch 및 16-batch 모드를 모두 지원

## 🛠️ 개발 과정 및 핵심 모듈
1. 기본 연산 유닛 (Adder & Multiplier)
가장 기초가 되는 8비트 Ripple Carry Adder와 4비트 부호 있는 곱셈기(Shift-and-Add 방식)를 구현했습니다. 이는 모든 상위 모듈의 핵심적인 연산 기반이 됩니다.

2. MAC (Multiply-and-Accumulate) 유닛
FC Layer의 핵심인 MAC 연산을 수행하는 모듈입니다. 8비트 입력 두 개를 곱하고 그 결과를 16비트 레지스터에 누적합니다. 4비트 곱셈기를 재활용하여 8비트 곱셈을 구현했으며, 5-cycle FSM으로 동작을 제어합니다.

3. 4x4 Systolic Array
16개의 MAC 유닛을 2차원 배열로 연결하여 4x4 행렬 곱셈을 병렬로 처리하는 Systolic Array를 Output Stationary 방식으로 구현했습니다. 이 구조는 데이터 재사용성을 극대화하여 행렬 곱셈 연산을 효율적으로 가속합니다.

<img width="825" height="524" alt="image" src="https://github.com/user-attachments/assets/95e8fe16-ad79-4e73-90db-440fbcdf56f8" />


4. Tiled Matrix Multiplication (8x8)
과제 4에서는 4x4 Systolic Array를 활용하여 더 큰 8x8 행렬 곱셈을 수행하기 위해 타일링(Tiling) 기법을 적용했습니다. Controller가 8x8 행렬을 4x4 크기의 타일로 나누고, 메모리에서 필요한 타일 데이터를 읽어와 Systolic Array에서 연산한 후, 부분 합을 누적하여 최종 결과를 완성합니다.


5. 최종 TNN 시스템 통합
최종적으로 모든 모듈을 통합하여 TNN 파이프라인을 완성했습니다.

<img width="960" height="669" alt="image" src="https://github.com/user-attachments/assets/cf9900bc-eb2b-46cf-994d-a163492facef" />
