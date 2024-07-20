/*

    Copyright (c) 2024 Pocketz World. All rights reserved.

    This is a generated file, do not edit!

    Generated by com.pz.studio
*/

#if UNITY_EDITOR

using System;
using System.Linq;
using UnityEngine;
using Highrise.Client;

namespace Highrise.Lua.Generated
{
    [AddComponentMenu("Lua/TeleporterController")]
    [LuaBehaviourScript(s_scriptGUID)]
    public class TeleporterController : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "27163c2b984a6134595cb6ab72683dc1";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public UnityEngine.Transform m_Destination = default;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), m_Destination),
            };
        }
    }
}

#endif