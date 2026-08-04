# Runtime Design

## 1. 목표

compiler가 만든 executable을 backend에서 실행하고 결과와 profile을 반환한다.

## 2. 최소 API

```python
executable = compile(graph, target)
result = run(executable, inputs, backend)
profile = profile(executable, inputs, backend)
```

## 3. Executable

포함 정보:

- ISA/contract version
- machine code
- memory map
- input/output metadata
- shape/dtype
- optional estimated instruction count

## 4. Buffer Lifecycle

```text
allocate
→ upload input
→ execute
→ download output
→ release
```

초기에는 static allocation을 사용한다.

## 5. Backend Interface

공통 interface:

```python
backend.load(executable)
backend.write_memory(address, data)
backend.start()
backend.wait()
backend.read_memory(address, size)
backend.get_trace()
backend.get_metrics()
```

Backend:

- functional simulator
- RTL simulator wrapper
- optional FPGA

## 6. Profile Metrics

최소:

- instruction count
- memory read/write count
- functional execution time
- cycle count if available
- backend status

## 7. Error Handling

- executable version mismatch
- invalid input shape/dtype
- backend error
- timeout
- output mismatch

## 8. Compiler와 Runtime의 경계

Compiler:

- graph 의미
- static memory map
- instruction 생성

Runtime:

- executable load
- 실제 buffer 준비
- backend lifecycle
- 결과와 profile 수집

## 9. 학습 질문

- 어떤 결정은 compile time에 고정하고 어떤 결정은 runtime에 남길 것인가?
- hardware 상태를 runtime이 관측하면 lowering 선택에 다시 사용할 수 있는가?
- 동일 executable을 여러 backend에서 실행할 수 있는가?
