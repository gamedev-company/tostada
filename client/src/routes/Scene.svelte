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
  // EXTENDING THIS SCENE
  //
  // Add a 3D object — place anywhere alongside the existing <T.Mesh>:
  //
  //   <T.Mesh position={[2, 0, 0]}>
  //     <T.SphereGeometry args={[0.5, 32, 32]} />
  //     <T.MeshStandardMaterial color="#38bdf8" />
  //   </T.Mesh>
  //
  // Load a GLTF/GLB model — add the import, then drop it in the template:
  //
  //   import { GLTF } from '@threlte/extras';      // add to imports above
  //   <GLTF url="/models/robot.glb" />              // add to template below
  //
  // Enable physics — npm install @threlte/rapier @dimforge/rapier3d-compat
  //   then wrap scene contents in <World>:
  //
  //   import { World, RigidBody, AutoColliders } from '@threlte/rapier';
  //
  //   <World gravity={[0, -9.81, 0]}>
  //     <AutoColliders shape="cuboid">
  //       <T.Mesh> ... </T.Mesh>
  //     </AutoColliders>
  //   </World>
  //
  // Add environment lighting — replace directional lights with:
  //
  //   import { Environment } from '@threlte/extras';
  //   <Environment url="/hdri/studio.hdr" />
  //
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
