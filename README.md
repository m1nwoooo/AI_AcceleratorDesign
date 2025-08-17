# AI_AcceleratorDesign
Designed and implemented a hardware accelerator for Tiny Neural Networks using Verilog HDL


Tiny Neural Network 하드웨어 가속기 설계 (Verilog)
본 프로젝트는 Tiny Neural Network(TNN)의 주요 연산을 Verilog HDL을 사용하여 하드웨어로 구현하고, 최종적으로 추론(Inference) 과정을 가속하는 시스템을 설계하는 것을 목표로 합니다. 설계는 기본적인 연산 유닛부터 시작하여 점차 복잡한 모듈을 통합하는 상향식(Bottom-up) 방식으로 진행되었습니다.

🚀 프로젝트 개요
최종적으로 구현된 TNN 가속기는 아래와 같은 구조를 가집니다. 외부 메모리에 저장된 입력 데이터(X)와 가중치(W1, W2)를 읽어와 두 개의 완전 연결 계층(Fully Connected Layer), 정규화(Normalization), ReLU 활성화 함수 연산을 순차적으로 수행하고, 최종 결과를 다시 메모리에 저장합니다.

주요 구성 요소:

FC Layer (행렬 곱셈기): 4x4 Systolic Array를 활용한 8x8 행렬 곱셈 연산

Normalization Layer: 입력값을 32로 나누는 연산 (Right Shift 5)

ReLU Layer: max(0, x) 활성화 함수 연산

Controller: 전체 데이터 흐름과 각 모듈의 동작을 제어하는 FSM

특징:

모듈화된 설계: Adder, Multiplier, MAC, Systolic Array 등 재사용 가능한 모듈 단위로 설계

타일링(Tiling): 4x4 연산 유닛을 활용하여 8x8 행렬 곱셈을 효율적으로 처리

파이프라이닝: 각 계층이 순차적으로 동작하며 데이터 처리량(Throughput) 향상

유연한 배치 처리: 8-batch 및 16-batch 모드를 모두 지원

🛠️ 개발 과정 및 핵심 모듈
1. 기본 연산 유닛 (Adder & Multiplier)
가장 기초가 되는 8비트 Ripple Carry Adder와 4비트 부호 있는 곱셈기(Shift-and-Add 방식)를 구현했습니다. 이는 모든 상위 모듈의 핵심적인 연산 기반이 됩니다.

2. MAC (Multiply-and-Accumulate) 유닛
FC Layer의 핵심인 MAC 연산을 수행하는 모듈입니다. 8비트 입력 두 개를 곱하고 그 결과를 16비트 레지스터에 누적합니다. 4비트 곱셈기를 재활용하여 8비트 곱셈을 구현했으며, 5-cycle FSM으로 동작을 제어합니다.

3. 4x4 Systolic Array
16개의 MAC 유닛을 2차원 배열로 연결하여 4x4 행렬 곱셈을 병렬로 처리하는 Systolic Array를 Output Stationary 방식으로 구현했습니다. 이 구조는 데이터 재사용성을 극대화하여 행렬 곱셈 연산을 효율적으로 가속합니다.

[Systolic Array 구조 이미지]

4. Tiled Matrix Multiplication (8x8)
과제 4에서는 4x4 Systolic Array를 활용하여 더 큰 8x8 행렬 곱셈을 수행하기 위해 타일링(Tiling) 기법을 적용했습니다. Controller가 8x8 행렬을 4x4 크기의 타일로 나누고, 메모리에서 필요한 타일 데이터를 읽어와 Systolic Array에서 연산한 후, 부분 합을 누적하여 최종 결과를 완성합니다.

[Tiled Matrix Multiplication 개념 이미지]

5. 최종 TNN 시스템 통합
최종적으로 모든 모듈을 통합하여 TNN 파이프라인을 완성했습니다.

데이터 흐름:

FC1: 외부 메모리의 Input X와 Weight W1을 읽어와 8x8 행렬 곱셈 수행 -> 결과를 내부 메모리 X1에 저장

NORM: X1의 결과를 읽어와 32로 나누는 정규화 연산 수행 -> 결과를 내부 메모리 X2에 저장

RELU: X2의 결과를 읽어와 ReLU 활성화 함수 적용 -> 결과를 내부 메모리 X3에 저장

FC2: X3의 결과와 Weight W2를 읽어와 두 번째 8x8 행렬 곱셈 수행 -> 최종 결과를 내부 메모리 X4 또는 X5에 저장

TRANSFER: 최종 결과를 외부 메모리 Y로 전송

중앙 컨트롤러: 전체 과정을 제어하는 FSM이 각 단계(IDLE, FC1, NORM, RELU, FC2, TRANSFER)를 순차적으로 진행하며, 메모리 주소 계산, 데이터 로드/저장, 각 모듈의 활성화 신호를 모두 관리합니다.

💡 결론 및 고찰
본 프로젝트를 통해 AI 모델의 기본 연산이 하드웨어 수준에서 어떻게 구현되고 가속되는지 심도 있게 이해할 수 있었습니다. 특히, 단순한 연산 유닛에서 시작하여 복잡한 Systolic Array와 전체 신경망 시스템으로 확장해나가는 과정을 통해 모듈화된 설계의 중요성을 체감했습니다.

또한, 타일링과 같은 기법이 제한된 하드웨어 자원으로 대규모 연산을 처리하는 데 얼마나 핵심적인 역할을 하는지 배울 수 있었습니다. 이는 실제 TPU나 GPU와 같은 AI 가속기 설계의 기본 원리를 이해하는 데 큰 도움이 되었습니다.
