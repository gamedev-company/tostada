<script lang="ts">
  import { T, useTask } from '@threlte/core';
  import { OrbitControls } from '@threlte/extras';
  import type { Mesh } from 'three';

  let mesh: Mesh | undefined = $state();
  let t = $state(0);

  useTask((delta) => {
    t += delta;
    if (mesh) {
      mesh.rotation.x += delta * 0.2;
      mesh.rotation.y += delta * 0.6;
      mesh.position.y = Math.sin(t) * 0.15;
    }
  });

  // ──────────────────────────────────────────────────────────────────────
  // HOW TO EXTEND THIS SCENE
  //
  // Add objects:
  //   <T.Mesh position={[2, 0, 0]}>
  //     <T.SphereGeometry args={[0.5, 32, 32]} />
  //     <T.MeshStandardMaterial color="#38bdf8" />
  //   </T.Mesh>
  //
  // Load a GLTF model:
  //   import { useGltf } from '@threlte/extras';
  //   const gltf = useGltf('/models/robot.glb');
  //   Then in template: {#if gltf}<T is={gltf.scene} />{/if}
  //
  // Add physics (install @threlte/rapier + @dimforge/rapier3d-compat):
  //   import { World, RigidBody, Collider } from '@threlte/rapier';
  //   Wrap scene contents in <World>, then:
  //   <RigidBody type="dynamic">
  //     <Collider shape="cuboid" args={[0.8, 0.2, 0.5]} />
  //     <T.Mesh> ... </T.Mesh>
  //   </RigidBody>
  //
  // Post-processing (install @threlte/extras EffectComposer):
  //   import { EffectComposer, Bloom } from '@threlte/extras';
  //   <EffectComposer><Bloom intensity={0.5} /></EffectComposer>
  // ──────────────────────────────────────────────────────────────────────
</script>

<T.PerspectiveCamera
  makeDefault
  position={[0, 1.2, 4]}
  fov={45}
  oncreate={(ref) => { ref.lookAt(0, 0, 0) }}
>
  <OrbitControls enableZoom={false} enablePan={false} />
</T.PerspectiveCamera>

<T.AmbientLight intensity={0.6} />
<T.DirectionalLight position={[4, 6, 5]} intensity={1.1} />
<T.DirectionalLight position={[-4, -3, -2]} intensity={0.4} color="#7dd3fc" />

<T.Mesh bind:ref={mesh} position={[0, 0, 0]}>
  <T.BoxGeometry args={[1.6, 0.4, 1.0]} />
  <T.MeshStandardMaterial color="#f59e0b" metalness={0.2} roughness={0.35} />
</T.Mesh>
