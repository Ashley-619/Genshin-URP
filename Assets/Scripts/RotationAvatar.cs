using System.Collections;
using System.Collections.Generic;
using UnityEngine;



public class RotateManage : MonoBehaviour
{
    public float rotationAvatarSpeed = 10.0f;

    public Light DLight = null;
    public GameObject AvatarObj = null;
    void Update()
    {
        Quaternion rotationStep = Quaternion.Euler(0, rotationAvatarSpeed * Time.deltaTime, 0);
        transform.localRotation = transform.localRotation * rotationStep;


    }
}