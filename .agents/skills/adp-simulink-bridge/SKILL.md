---
name: adp-simulink-bridge
description: Adapt MATLAB ADP controllers to Simulink with explicit state, sampling and signal contracts, then compare offline behavior. Use for MATLAB-to-Simulink migration or controller integration.
---

# MATLAB to Simulink ADP integration

Inspect the actual model, MATLAB controller and target environment first. Preserve the original model. Establish state/input units and frames, fixed dimensions, reset semantics, sample times, solver, communication timing and expected actuator command.

Separate controller state and parameter configuration from the MATLAB base workspace. Define explicit buses/structures and initialization/reset behavior. Make continuous learning states continuous states, and sampled updates discrete states with a known update event.

Check direct-feedthrough/algebraic loops, multiple-rate transitions, hold behavior, saturation and sample ordering. Log each command stage through the final simulated actuator and re-evaluate any associated learning or certificate equations.

First validate with offline prerecorded input replay or a software-only plant. Compare output and state trajectories with the MATLAB reference using documented time alignment and tolerances. Identify expected differences caused by sampling or integration separately from implementation bugs.

Only constrain functions to code-generation subsets when the requested target needs code generation. Declare toolbox, release, generated-code and hardware dependencies; do not add unnecessary dependencies to the base ADP library.

Report MATLAB simulation, Simulink simulation, code generation, SIL/PIL/HIL and live hardware as separate stages. Software migration authorization does not authorize connecting or commanding hardware. Keep device callbacks and external actuation outside offline verification.

## Method expansion checks

Preserve physical, sensor, controller and learner clocks separately; continuous policy-iteration time is not plant time. Do not replace SDE with random ODE inputs without a declared approximation. Learned filters, feature dictionaries, policy versions and actual input channels require state and reset contracts. A stochastic/PDE optional backend needs its own equivalence checks.
