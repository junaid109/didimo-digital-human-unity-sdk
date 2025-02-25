using System.Collections;
using System.Collections.Generic;
using System.Linq;
#if USING_LIVE_CAPTURE
using Unity.LiveCapture.ARKitFaceCapture;
using UnityEngine;

namespace Didimo.LiveCapture
{
    /// <summary>
    /// FaceMapper class to use didimos along with Unity's ARKit LiveCapture Integration.
    /// Maps the names of the shapes received from ARKit and triggers the appropriate animations.
    /// </summary>
    [CreateAssetMenu(fileName = "DidimoFaceMapper", menuName = "Didimo/ARKit Face Capture/DidimoFaceMapper")]
    public class DidimoLiveCaptureMapper : FaceMapper
    {
        /// <summary>
        /// Cache object that contains a map of the received blendshapes to their proper names
        /// and a reference to the PoseController to trigger the animations.
        /// </summary>
        private class Cache : FaceMapperCache
        {
            private readonly DidimoComponents didimoComponents;
            public DidimoPoseController PoseController => didimoComponents.PoseController;
            public readonly Dictionary<FaceBlendShape, string> PoseNameMapper;

            public Cache(DidimoComponents didimoComponents)
            {
                this.didimoComponents = didimoComponents;
                PoseNameMapper = new Dictionary<FaceBlendShape, string>(FaceBlendShapePose.ShapeCount);
                foreach (FaceBlendShape shape in FaceBlendShapePose.Shapes)
                {
                    string shapeName = shape.ToString();
                    PoseNameMapper[shape] = $"ARKit_{RemapShapeName(shapeName)}";
                }
            }
        }

        public static string RemapShapeName(string shapeName)
        {
            return  $"{shapeName.First().ToString().ToLower()}{shapeName.Substring(1)}";
        }

        public override FaceMapperCache CreateCache(FaceActor actor)
        {
            DidimoComponents didimoComponents = actor.GetComponent<DidimoComponents>();

            if (didimoComponents != null) return new Cache(didimoComponents);
            return null;
        }


        public override void ApplyBlendShapesToRig(
            FaceActor actor, FaceMapperCache cache, ref FaceBlendShapePose pose, bool continuous)
        {
            // Possible improvements at DefaultFaceMapper.ApplyBlendShapesToRig (line 231)
            if (!Application.isPlaying) return;
            Cache c = (Cache) cache;
            foreach (FaceBlendShape faceBlendShape in FaceBlendShapePose.Shapes)
            {
                c.PoseController.SetWeightForPose(c.PoseNameMapper[faceBlendShape], pose.GetValue(faceBlendShape));
            }
        }

        public override void ApplyHeadPositionToRig(FaceActor actor, FaceMapperCache cache, ref Vector3 headPosition, bool continuous)
        {
            if (!Application.isPlaying) return;
            Cache c = (Cache) cache;
            c.PoseController.SetHeadPosition(headPosition);
        }

        public override void ApplyHeadRotationToRig(FaceActor actor, FaceMapperCache cache, ref Quaternion headOrientation, bool continuous)
        {
            // Ensure play mode otherwise head transform gets messed up and then further transformations no longer reset it properly.
            if (!Application.isPlaying) return;
            Cache c = (Cache) cache;
            c.PoseController.SetHeadRotation(headOrientation);
        }

        public override void ApplyEyeRotationToRig(FaceActor actor, FaceMapperCache cache, ref FaceBlendShapePose pose, ref Quaternion leftEyeRotation, ref Quaternion rightEyeRotation, bool continuous)
        {
            if (!Application.isPlaying) return;
            Cache c = (Cache) cache;
            c.PoseController.SetLeftEyeRotation(leftEyeRotation);
            c.PoseController.SetRightEyeRotation(rightEyeRotation);
        }
    }
}
#endif