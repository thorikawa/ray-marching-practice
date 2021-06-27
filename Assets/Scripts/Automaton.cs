using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Automaton : MonoBehaviour
{
    [SerializeField] private Material material;
    [SerializeField] private float fps = 10.0f;
    private int frame = 0;

    // Start is called before the first frame update
    void Start()
    {
        material.SetFloat("_Interval", 1.0f / fps);
        StartCoroutine(FpsLoop());
    }

    void Update()
    {
        material.SetFloat("_CurTime", Time.time);
    }
    IEnumerator FpsLoop()
    {
        while (true)
        {
            yield return new WaitForSeconds(0.999f / fps);
            LocalUpdate();
        }
    }

    // Update is called once per frame
    void LocalUpdate()
    {
        var tex = Resources.Load<Texture2D>($"sdf/sdf{frame}");
        material.mainTexture = tex;
        var tex2 = Resources.Load<Texture2D>($"sdf/sdf{frame + 1}");
        material.SetTexture("_NextTex", tex2);
        material.SetFloat("_SetTime", Time.time);
        frame++;
    }
}
