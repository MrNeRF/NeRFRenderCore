#pragma once

/**
 * 4x4 transformation matrix helpers, optimized for 3D graphics
 * by James Perlman, 2023 (with lots of help from ChatGPT and GitHub Copilot!) 
 */

#include <json/json.hpp>

#include "../../common.h"
#include "../linalg.cuh"

NRC_NAMESPACE_BEGIN

struct alignas(float) Transform4f
{
    float m00, m01, m02, m03;
    float m10, m11, m12, m13;
    float m20, m21, m22, m23;

    float* data() { return &m00; }

    /** Constructors **/

    Transform4f() = default;

    NRC_HOST_DEVICE Transform4f(Matrix4f m)
        : m00(m.m00), m01(m.m01), m02(m.m02), m03(m.m03)
        , m10(m.m10), m11(m.m11), m12(m.m12), m13(m.m13)
        , m20(m.m20), m21(m.m21), m22(m.m22), m23(m.m23)
    {};

    NRC_HOST_DEVICE Transform4f(
        const float& m00, const float& m01, const float& m02, const float& m03,
        const float& m10, const float& m11, const float& m12, const float& m13,
        const float& m20, const float& m21, const float& m22, const float& m23)
        : m00(m00), m01(m01), m02(m02), m03(m03)
        , m10(m10), m11(m11), m12(m12), m13(m13)
        , m20(m20), m21(m21), m22(m22), m23(m23)
    {};

    // json constructor, mij = data[i][j]
    Transform4f(const nlohmann::json& data)
    {
        m00 = data[0][0]; m01 = data[0][1]; m02 = data[0][2]; m03 = data[0][3];
        m10 = data[1][0]; m11 = data[1][1]; m12 = data[1][2]; m13 = data[1][3];
        m20 = data[2][0]; m21 = data[2][1]; m22 = data[2][2]; m23 = data[2][3];
    }

    /** Debug **/

    void print() const
    {
        printf("%f %f %f %f\n", m00, m01, m02, m03);
        printf("%f %f %f %f\n", m10, m11, m12, m13);
        printf("%f %f %f %f\n", m20, m21, m22, m23);
        printf("%f %f %f %f\n", 0.0f, 0.0f, 0.0f, 1.0f);
        printf("\n");
    }

    /** Convenience Initializers **/
    
    static Transform4f Identity()
    {
        return Transform4f{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
        };
    }

    // Generated by ChatGPT, creates a rotation matrix from an angle and an axis
    static Transform4f Rotation(float angle, float x, float y, float z)
    {
        // angle is expected to be in radians
        float c = cosf(angle);
        float s = sinf(angle);

        return Transform4f{
            x * x * (1 - c) + c,        y * x * (1 - c) + z * s,  x * z * (1 - c) - y * s,  0,
            x * y * (1 - c) - z * s,    y * y * (1 - c) + c,      y * z * (1 - c) + x * s,  0,
            x * z * (1 - c) + y * s,    y * z * (1 - c) - x * s,  z * z * (1 - c) + c,      0,            
        };
    }

    // create a translation matrix
    static Transform4f Translation(const float& x, const float& y, const float& z)
    {
        return Transform4f{
            1, 0, 0, x,
            0, 1, 0, y,
            0, 0, 1, z,
        };
    }

    // create a scale matrix
    static Transform4f Scale(const float& x, const float& y, const float& z)
    {
        return Transform4f{
            x, 0, 0, 0,
            0, y, 0, 0,
            0, 0, z, 0,
        };
    }

    static Transform4f Scale(const float& s) {
        return Scale(s, s, s);
    }

    /** Operators **/

        // multiplication operator with float3 - multiply by upper left 3x3, no translation
    inline NRC_HOST_DEVICE float3 mmul_ul3x3(const float3& v) const
    {
        return make_float3(
            m00 * v.x + m01 * v.y + m02 * v.z,
            m10 * v.x + m11 * v.y + m12 * v.z,
            m20 * v.x + m21 * v.y + m22 * v.z
        );
    }

    // multiplication operator with float3 - assume we want v to be inferred as homogeneous
    inline NRC_HOST_DEVICE float3 operator*(const float3& v) const
    {
        return make_float3(
            m00 * v.x + m01 * v.y + m02 * v.z + m03,
            m10 * v.x + m11 * v.y + m12 * v.z + m13,
            m20 * v.x + m21 * v.y + m22 * v.z + m23
        );
    }

    // multiplication operator with other Transform4f
    inline NRC_HOST_DEVICE Transform4f operator*(const Transform4f& x) const
    {
        return Transform4f{
            m00 * x.m00 + m01 * x.m10 + m02 * x.m20,
            m00 * x.m01 + m01 * x.m11 + m02 * x.m21,
            m00 * x.m02 + m01 * x.m12 + m02 * x.m22,
            m00 * x.m03 + m01 * x.m13 + m02 * x.m23 + m03,

            m10 * x.m00 + m11 * x.m10 + m12 * x.m20,
            m10 * x.m01 + m11 * x.m11 + m12 * x.m21,
            m10 * x.m02 + m11 * x.m12 + m12 * x.m22,
            m10 * x.m03 + m11 * x.m13 + m12 * x.m23 + m13,

            m20 * x.m00 + m21 * x.m10 + m22 * x.m20,
            m20 * x.m01 + m21 * x.m11 + m22 * x.m21,
            m20 * x.m02 + m21 * x.m12 + m22 * x.m22,
            m20 * x.m03 + m21 * x.m13 + m22 * x.m23 + m23,
        };
    }

    // convenience getter, returns the translation of this matrix as a float3
    inline NRC_HOST_DEVICE float3 get_translation() const
    {
        return make_float3(m03, m13, m23);
    }

    float determinant() const
    {
        return 0.0f
            + m00 * (m11 * m22 - m12 * m21)
            - m01 * (m10 * m22 - m12 * m20)
            + m02 * (m10 * m21 - m11 * m20);
    }

    Transform4f inverse() const
    {
        const float m11_x_m22_m_m12_x_m21 = m11 * m22 - m12 * m21;
        const float m10_x_m22_m_m12_x_m20 = m10 * m22 - m12 * m20;
        const float m10_x_m21_m_m11_x_m20 = m10 * m21 - m11 * m20;

        const float det = m00 * (m11_x_m22_m_m12_x_m21) - m01 * (m10_x_m22_m_m12_x_m20) + m02 * (m10_x_m21_m_m11_x_m20);

        const float i_det = 1.0f / det;

        const float m12_x_m23_m_m13_x_m22 = m12 * m23 - m13 * m22;
        const float m11_x_m23_m_m13_x_m21 = m11 * m23 - m13 * m21;
        const float m10_x_m23_m_m13_x_m20 = m10 * m23 - m13 * m20;

        return Transform4f{
            + (m11_x_m22_m_m12_x_m21) * i_det,
            - (m01 * m22 - m02 * m21) * i_det,
            + (m01 * m12 - m02 * m11) * i_det,
            - (m01 * (m12_x_m23_m_m13_x_m22) - m02 * (m11_x_m23_m_m13_x_m21) + m03 * (m11_x_m22_m_m12_x_m21)) * i_det,
            - (m10_x_m22_m_m12_x_m20) * i_det,
            + (m00 * m22 - m02 * m20) * i_det,
            - (m00 * m12 - m02 * m10) * i_det,
            + (m00 * (m12_x_m23_m_m13_x_m22) - m02 * (m10_x_m23_m_m13_x_m20) + m03 * (m10_x_m22_m_m12_x_m20)) * i_det,
            + (m10_x_m21_m_m11_x_m20) * i_det,
            - (m00 * m21 - m01 * m20) * i_det,
            + (m00 * m11 - m01 * m10) * i_det,
            - (m00 * (m11_x_m23_m_m13_x_m21) - m01 * (m10_x_m23_m_m13_x_m20) + m03 * (m10_x_m21_m_m11_x_m20)) * i_det,
        };
    }

    // coordinate transformations
    Transform4f from_nerf() const {
        Transform4f nerf_matrix(*this);
        Transform4f result = nerf_matrix;
        // invert column 1
        result.m01 = -nerf_matrix.m01;
        result.m11 = -nerf_matrix.m11;
        result.m21 = -nerf_matrix.m21;
        // result.m31 = -nerf_matrix.m31;

        // invert column 2
        result.m02 = -nerf_matrix.m02;
        result.m12 = -nerf_matrix.m12;
        result.m22 = -nerf_matrix.m22;
        // result.m32 = -nerf_matrix.m32;

        // roll axes xyz -> yzx
        const Transform4f tmp = result;
        // x -> y
        result.m00 = tmp.m10; result.m01 = tmp.m11; result.m02 = tmp.m12; result.m03 = tmp.m13;
        // y -> z
        result.m10 = tmp.m20; result.m11 = tmp.m21; result.m12 = tmp.m22; result.m13 = tmp.m23;
        // z -> x
        result.m20 = tmp.m00; result.m21 = tmp.m01; result.m22 = tmp.m02; result.m23 = tmp.m03;
        
        return result;
    }
};

NRC_NAMESPACE_END
